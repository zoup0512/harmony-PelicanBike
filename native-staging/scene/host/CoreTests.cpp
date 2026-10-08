#include "../RenderScene.h"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <iostream>
#include <limits>
#include <set>
#include <vector>

using namespace pelican::scene;

namespace {

bool finiteMatrix(const Mat4& matrix) {
    return std::all_of(matrix.m.begin(), matrix.m.end(), [](float value) { return std::isfinite(value); });
}

void validateMesh(const CpuMesh& mesh, size_t maximumTriangles) {
    assert(!mesh.empty());
    assert(mesh.indices.size() % 3 == 0);
    assert(mesh.indices.size() / 3 <= maximumTriangles);
    for (const Vertex& vertex : mesh.vertices) {
        assert(vertex.position.finite());
        assert(vertex.normal.finite());
        assert(vertex.color.finite());
    }
    for (uint32_t index : mesh.indices) assert(index < mesh.vertices.size());
}

void testLongDistanceWaves() {
    const double distance = 1.0e12 + 12345.6789;
    const double time = 4.2e7;
    const auto phases = computeWavePhases(distance, time);
    for (float phase : phases) {
        assert(std::isfinite(phase));
        assert(std::abs(phase) <= kTau + 1.0e-4f);
    }
    for (double z : {-13.0, -42.0, -300.0}) {
        const double height = waveHeight(distance + 123.5, z, time, 1.2);
        assert(std::isfinite(height));
        assert(height > -10.0 && height < 10.0);
    }
}

void testPaletteAndDayNight() {
    for (float hour = 0.0f; hour < 24.0f; hour += 0.125f) {
        const Vec3 sun = sunDirection(hour);
        const Vec3 moon = moonDirection(hour);
        assert(sun.finite() && moon.finite());
        assert(std::abs(sun.length() - 1.0f) < 1.0e-3f);
        assert(std::abs(moon.length() - 1.0f) < 1.0e-3f);
    }
    for (float elevation = -30.0f; elevation <= 80.0f; elevation += 0.25f) {
        const SkyPalette palette = sampleSkyPalette(elevation);
        assert(palette.zenith.finite() && palette.horizon.finite() && palette.fogColor.finite());
        assert(std::isfinite(palette.exposure) && std::isfinite(palette.bloom));
        const float night = nightFactor(elevation);
        assert(night >= 0.0f && night <= 1.0f);
    }
    assert(nightFactor(-20.0f) > 0.99f);
    assert(nightFactor(20.0f) < 0.01f);
}

void testChunkPrecision() {
    const double distance = 1.0e12 + 13.25;
    const auto chunks = computeChunkPlacements(distance);
    std::set<int64_t> unique;
    for (const ChunkPlacement& chunk : chunks) {
        unique.insert(chunk.index);
        assert(std::isfinite(chunk.localX));
        assert(std::abs(chunk.localX) < 400.0f);
    }
    assert(unique.size() == kWorldChunkCount);
    for (size_t i = 1; i < chunks.size(); ++i) {
        assert(chunks[i].index == chunks[i - 1].index + 1);
        assert(std::abs((chunks[i].localX - chunks[i - 1].localX) - 72.0f) < 0.01f);
    }
}

void testGeometry() {
    validateMesh(makeOceanGrid(0), 12000);
    validateMesh(makeOceanGrid(1), 28000);
    validateMesh(makeOceanGrid(2), 55000);
    validateMesh(makeTerrainChunk(2), 5000);
    validateMesh(makeTreeMesh(), 1500);
    validateMesh(makePineMesh(), 800);
    validateMesh(makePalmMesh(), 2500);
    validateMesh(makeRockMesh(), 500);
    validateMesh(makeLampMesh(), 1000);
    validateMesh(makeGuardrailChunk(), 1000);
    validateMesh(makeLighthouseMesh(), 2500);
    validateMesh(makeBoatMesh(), 1500);
    validateMesh(makeBirdBodyMesh(false), 600);
    validateMesh(makeBirdWingMesh(true), 100);
    validateMesh(makeBicycleMesh(), 6000);
    validateMesh(makePelicanBodyMesh(), 1000);
    validateMesh(makePelicanHeadMesh(), 1500);
    validateMesh(makePelicanBeakMesh(), 1500);
    validateMesh(makePelicanWingMesh(), 200);
    validateMesh(makeFishMesh(), 1000);
}

void testScarfFiniteGuardsAndCapacity() {
    ScarfSimulation scarf;
    const Vec3 a{0.0f, 1.4f, -0.04f};
    const Vec3 b{0.0f, 1.4f, 0.04f};
    scarf.reset(a, b);
    const ScarfCollider collider{{0.1f, 1.1f, 0.0f}, 0.3f};
    CpuMesh scratch;
    scratch.vertices.reserve(ScarfSimulation::kPointCount);
    scratch.indices.reserve((ScarfSimulation::kSegments - 1) * 6);
    const size_t vertexCapacity = scratch.vertices.capacity();
    const size_t indexCapacity = scratch.indices.capacity();
    constexpr int tenMinutesAt60Hz = 10 * 60 * 60;
    for (int i = 0; i < tenMinutesAt60Hz; ++i) {
        scarf.update(i == 20 ? 0.5f : 1.0f / 60.0f, a, b, {-8.0f, 0.2f, 0.5f}, i / 60.0f, &collider);
        assert(scarf.finite());
        if ((i % 120) == 0) {
            scarf.fillMesh(scratch);
            assert(scratch.vertices.capacity() == vertexCapacity);
            assert(scratch.indices.capacity() == indexCapacity);
        }
    }
    scarf.injectNonFiniteForTest();
    assert(!scarf.finite());
    scarf.update(1.0f / 60.0f, a, b, {-8.0f, 0.2f, 0.5f}, 601.0f, &collider);
    assert(scarf.finite());
    scarf.fillMesh(scratch);
    for (const Vertex& vertex : scratch.vertices) {
        assert(vertex.position.finite());
        assert(vertex.normal.finite());
        assert(vertex.normal.lengthSquared() > 1.0e-8f);
    }
}

void testParticleCapacity() {
    ParticleSystem system(8);
    for (int i = 0; i < 100; ++i) {
        Particle particle;
        particle.position = {static_cast<float>(i), 1, 0};
        particle.velocity = {1, 1, 0};
        particle.life = particle.maxLife = 1.0f;
        system.emit(particle);
    }
    assert(system.particles().size() == 8);
    assert(system.aliveCount() == 8);
    system.update(2.0f, 0.0f);
    assert(system.particles().size() == 8);
}

void testCharacterAnimator() {
    CharacterAnimator animator;
    for (int i = 0; i < 6000; ++i) {
        AnimationInputs input;
        input.time = std::fmod(i / 60.0f, 10000.0f);
        input.deltaTime = 1.0f / 60.0f;
        input.speed = 14.0f + std::sin(i * 0.01f) * 4.0f;
        input.steering = std::sin(i * 0.03f);
        input.pedal = 1.0f;
        input.airborne = saturate(std::sin(i * 0.011f));
        input.trick = saturate(std::sin(i * 0.007f));
        input.mouthOpen = saturate(std::sin(i * 0.02f));
        animator.update(input);
        const AnimatedNodes& nodes = animator.nodes();
        assert(finiteMatrix(nodes.bicycle));
        assert(finiteMatrix(nodes.pelicanBody));
        assert(finiteMatrix(nodes.pelicanHead));
        for (const Mat4& fish : nodes.fish) assert(finiteMatrix(fish));
    }
}

void testMockGlLifecycleOrbitPickAndStats() {
    using namespace pelican::scene::mockgl;
    assert(liveBuffers == 0 && liveVertexArrays == 0 && liveTextures == 0 && livePrograms == 0);
    RenderScene scene;
    assert(scene.initialize(320, 180, Quality::High));
    const uint64_t highBuffers = liveBuffers;
    const uint64_t highVaos = liveVertexArrays;
    const uint64_t highTextures = liveTextures;
    RenderState state;
    state.totalDistance = 8.0e11;
    state.timeSeconds = 1234567.0;
    state.speedMetersPerSecond = 16.0f;
    state.useExternalCamera = false;
    scene.orbitDrag(500.0f, 500.0f);
    scene.orbitZoom(1.0e8f);
    scene.update(state);
    OrbitCameraState orbit = scene.orbitCameraState();
    assert(orbit.distance >= 1.1f && orbit.distance <= 28.0f);
    assert(orbit.pitch <= radians(89.0f) + 1.0e-5f);
    scene.orbitZoom(1.0e-8f);
    scene.update(state);
    orbit = scene.orbitCameraState();
    assert(orbit.distance >= 1.1f && orbit.distance <= 28.0f);
    scene.render();
    const RenderStats highStats = scene.stats();
    assert(highStats.drawCalls > 0 && highStats.triangles > 0);
    assert(highStats.programs == 9);
    assert(highStats.buffers == highBuffers);
    assert(highStats.vaos == highVaos);
    assert(highStats.textures == highTextures);
    assert(highStats.glErrors == 0);
    const auto pixels = scene.screenshotPixels();
    assert(pixels.size() == static_cast<size_t>(320 * 180 * 4));
    const PickTarget target = scene.pick(0.5f, 0.5f);
    assert(static_cast<int>(target) >= static_cast<int>(PickTarget::None));
    scene.destroy();
    assert(liveBuffers == 0 && liveVertexArrays == 0 && liveTextures == 0 && liveFramebuffers == 0 &&
           liveRenderbuffers == 0 && livePrograms == 0);

    assert(scene.initialize(160, 90, Quality::Low));
    state.timeSeconds += 1.0;
    scene.update(state);
    scene.render();
    const RenderStats lowStats = scene.stats();
    assert(lowStats.framebuffers == 0);
    scene.destroy();
    assert(liveBuffers == 0 && liveVertexArrays == 0 && liveTextures == 0 && liveFramebuffers == 0 &&
           liveRenderbuffers == 0 && livePrograms == 0);
}

}  // namespace

int main() {
    testLongDistanceWaves();
    testPaletteAndDayNight();
    testChunkPrecision();
    testGeometry();
    testScarfFiniteGuardsAndCapacity();
    testParticleCapacity();
    testCharacterAnimator();
    testMockGlLifecycleOrbitPickAndStats();
    std::cout << "pelican scene core tests passed\n";
    return 0;
}
