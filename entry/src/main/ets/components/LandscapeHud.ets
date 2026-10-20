import { CameraMode, GameAction, GameSettings, GameTelemetry, ToolAction, formatClock } from '../model/GameModels';

@Component
export struct LandscapeHud {
  @Prop telemetry: GameTelemetry = new GameTelemetry();
  @Prop settings: GameSettings = new GameSettings();
  @Prop safeLeft: number = 0;
  @Prop safeRight: number = 0;
  @Prop safeTop: number = 0;
  @Prop paused: boolean = false;
  @State private camerasOpen: boolean = false;
  @State private toolsOpen: boolean = false;
  onCamera: (mode: CameraMode) => void = (_mode: CameraMode): void => {};
  onTool: (action: ToolAction) => void = (_action: ToolAction): void => {};
  onPause: () => void = (): void => {};

  @Builder
  private menuButton(label: string, selected: boolean, callback: () => void) {
    Button(label, { type: ButtonType.Normal })
      .height(38)
      .padding({ left: 12, right: 12 })
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(selected ? '#FFE0A4' : '#E8F3FA')
      .backgroundColor(selected ? '#CB38495B' : '#B0182B3C')
      .borderRadius(10)
      .border({ width: 1, color: selected ? '#B5D7AD68' : '#48658A9F' })
      .onClick(callback)
  }

  @Builder
  private cameraButton(label: string, mode: CameraMode) {
    this.menuButton(label, this.telemetry.camera === mode, (): void => {
      this.onCamera(mode);
      this.camerasOpen = false;
    })
  }

  build() {
    Stack() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column({ space: 5 }) {
          Row({ space: 10 }) {
            Text(Math.round(this.telemetry.speedKmh).toString())
              .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
            Column({ space: 2 }) {
              Text('KM/H').fontSize(9).fontColor('#AAC9DB')
              Text('档位 ' + this.telemetry.gear.toString() + '/5').fontSize(10).fontColor('#DCECF4')
            }.alignItems(HorizontalAlign.Start)
            Text('鱼 ' + this.telemetry.fishCount.toString())
              .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#FFD490')
          }
          Row({ space: 9 }) {
            Text(this.telemetry.distanceKm.toFixed(2) + ' km').fontSize(10).fontColor('#B8D0DD')
            Text('成就 ' + this.telemetry.achievementCount.toString() + '/14').fontSize(10).fontColor('#B8D0DD')
            Text(formatClock(this.telemetry.hour)).fontSize(10).fontColor('#B8D0DD')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12, right: 12, top: 7, bottom: 8 })
        .backgroundColor('#B0182B3C').borderRadius(12)
        .border({ width: 1, color: '#48658A9F' })
        .hitTestBehavior(HitTestMode.None)
      }
      .width('100%').height('100%')
      .padding({ left: Math.max(14, this.safeLeft + 10), top: Math.max(10, this.safeTop + 6) })
      .hitTestBehavior(HitTestMode.Transparent)

      Stack({ alignContent: Alignment.TopEnd }) {
        Column({ space: 7 }) {
          Row({ space: 6 }) {
            this.menuButton('镜头', this.camerasOpen, (): void => {
              this.camerasOpen = !this.camerasOpen;
              this.toolsOpen = false;
            })
            this.menuButton('设置', false, (): void => { this.onTool(ToolAction.SETTINGS); })
            Button(this.paused ? '继续' : '暂停', { type: ButtonType.Normal })
              .height(38).padding({ left: 12, right: 12 }).fontSize(12)
              .fontColor(this.paused ? '#FFE0A4' : '#E8F3FA')
              .backgroundColor(this.paused ? '#CB38495B' : '#B0182B3C')
              .border({ width: 1, color: '#48658A9F', radius: 10 })
              .onClick((): void => { this.onPause(); })
            this.menuButton('更多', this.toolsOpen, (): void => {
              this.toolsOpen = !this.toolsOpen;
              this.camerasOpen = false;
            })
          }
          if (this.camerasOpen) {
            Row({ space: 4 }) {
              this.cameraButton('环绕', CameraMode.ORBIT)
              this.cameraButton('追随', CameraMode.CHASE)
              this.cameraButton('侧拍', CameraMode.SIDE)
              this.cameraButton('电影', CameraMode.CINE)
              this.cameraButton('第一视角', CameraMode.POV)
            }
            .padding(6).backgroundColor('#E0102030').borderRadius(12)
          }
          if (this.toolsOpen) {
            Column({ space: 5 }) {
              Row({ space: 5 }) {
                this.menuButton('截图', false, (): void => { this.onTool(ToolAction.SCREENSHOT); })
                this.menuButton('音乐', this.settings.music, (): void => { this.onTool(ToolAction.MUSIC); })
                this.menuButton('帮助', false, (): void => { this.onTool(ToolAction.HELP); })
              }
              Row({ space: 5 }) {
                this.menuButton('分享', false, (): void => { this.onTool(ToolAction.SHARE); })
                this.menuButton('源码', false, (): void => { this.onTool(ToolAction.GITHUB); })
                this.menuButton('作者', false, (): void => { this.onTool(ToolAction.X); })
              }
            }
            .padding(6).backgroundColor('#E0102030').borderRadius(12)
          }
          if (this.settings.showFps) {
            Text(Math.round(this.telemetry.fps).toString() + ' FPS')
              .fontSize(10).fontColor('#A7DED7')
          }
        }.alignItems(HorizontalAlign.End)
      }
      .width('100%').height('100%')
      .padding({ right: Math.max(14, this.safeRight + 10), top: Math.max(10, this.safeTop + 6) })
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .width('100%').height('100%').hitTestBehavior(HitTestMode.Transparent)
  }
}
