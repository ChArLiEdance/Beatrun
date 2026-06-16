# Goal Prompt: Watch Standalone Workout And Music Library Matching

目标：继续完善 Beatrun，使 Apple Watch 端可以独立运行，接入 HealthKit / Workout Session，并把音乐来源从 generated loop 改为系统音乐库/用户授权音乐库。完成后提交并 push 到 GitHub。

## 当前背景

Beatrun 已经有 iOS 比赛 Demo 风格界面、Watch companion 大框、WatchConnectivity 共享状态结构、1:1 BPM 匹配、+/-10% 变速上限、队列预加载、crossfade MVP。现在要把项目从 generated-loop 演示推进到更接近真实跑步训练产品。

## 核心约束

1. 仍然只做 1:1 BPM 与目标步频匹配。
2. 音乐变速上限仍为 +/-10%。
3. 不使用 double-time / half-time / 双倍步频匹配。
4. 不再把 generated loop 作为主要播放音乐。
5. 音乐必须来自用户授权的系统音乐库、用户本地导入音乐、MusicKit/MediaPlayer 可合法播放来源，或明确 royalty-free/CC 授权文件。
6. 不实现任何未授权下载、抓取、解密、复制、分发商业音乐的逻辑。
7. 如果 Apple Music/DRM 音频无法直接分析波形或变速，要在代码和文档中清楚说明限制，并采用合法替代方案，例如 BPM 元数据、用户手动标注 BPM、授权本地音频文件。
8. 不破坏当前 iOS 核心演示流程。
9. 不覆盖或回滚已有改动，除非我明确要求。

## 任务一：修复并完善 Watch 端，使其可以独立运行

需要完成：

1. Watch App 在 iPhone 不可达时也能打开并进入可用状态。
2. Watch 端要有本地状态模型，例如：
   - target cadence；
   - workout running / paused；
   - metronome running / paused；
   - current cadence；
   - elapsed time；
   - sync status；
   - iPhone connection status。
3. WatchConnectivity 只作为同步增强，不作为 Watch 基础功能的硬依赖。
4. 当 iPhone 不可达时，Watch 显示 Standalone Mode / Local Workout Mode，而不是卡死或空白。
5. Watch 端至少支持：
   - Start Workout；
   - Pause / Resume；
   - End Workout；
   - target cadence 查看；
   - 如果实现成本可控，支持 -5 / +5 调整目标步频；
   - 显示当前步频和目标步频差值。
6. Watch UI 要适合小屏幕，不堆长文本，重点显示大号 cadence、状态和控制按钮。
7. 如果有连接问题，要显示清楚的状态，例如：
   - iPhone connected；
   - Watch sync delayed；
   - Standalone workout active。

## 任务二：实现 HealthKit / Workout Session

需要完成：

1. 新增 Watch 端 WorkoutManager 或同等结构。
2. 使用 HealthKit 请求权限。
3. 使用 HKWorkoutSession / HKLiveWorkoutBuilder 管理跑步 workout。
4. 记录或展示：
   - workout elapsed time；
   - heart rate 如果可用；
   - active energy 如果可用；
   - distance 如果可用；
   - current cadence 如果可通过 CoreMotion/CMPedometer 获取。
5. 如果 HealthKit 不能直接提供实时步频，使用 CoreMotion / CMPedometer 获取 live cadence，并在文档里说明。
6. Workout 开始时启动本地步频显示和 metronome 状态。
7. Workout 暂停/恢复/结束状态要同步到 Watch UI。
8. 不要为了 HealthKit 引入不稳定实现；如果模拟器无法提供真实数据，要提供 mock/fallback 状态，并记录限制。
9. README 和 docs/dev-log.md 要写清楚 HealthKit 权限、模拟器限制、真机验证建议。

## 任务三：把音乐来源改为系统音乐库/用户授权音乐

需要完成：

1. 移除或弱化 generated loop 作为主播放源的产品路径。
2. 新增音乐库访问层，例如 MusicLibraryService / TrackProvider。
3. 使用合法系统 API：
   - MediaPlayer / MPMediaLibrary；
   - MusicKit；
   - Document Picker 导入用户授权音频；
   - 或项目内明确授权的 royalty-free / CC 文件。
4. App 需要请求音乐库权限，并处理用户拒绝权限的情况。
5. 音乐曲目模型要记录：
   - title；
   - artist；
   - original BPM；
   - adjusted BPM；
   - tempo shift percentage；
   - rights/source；
   - whether tempo adjustment is allowed；
   - whether waveform analysis is available。
6. 如果系统音乐库曲目没有 BPM：
   - 不要瞎猜；
   - 可以显示 Needs BPM；
   - 支持用户手动输入 BPM；
   - 或只推荐有 BPM 元数据/授权 metadata 的曲目。
7. 推荐算法仍然只允许：
   - adjusted BPM 接近 target cadence；
   - tempo shift 在 +/-10% 内；
   - 1:1 matching only。
8. UI 中明确展示音乐来源：
   - Apple Music / Local Library / Imported File / CC Licensed；
   - 是否可分析；
   - 是否可变速。
9. 如果 DRM 或 API 限制导致无法变速 Apple Music 音频，要实现清楚 fallback：
   - 只作为 metadata recommendation；
   - 或要求使用本地导入/授权音频进行实际变速播放；
   - 不要假装已经能对所有 Apple Music 歌曲变速。
10. 不要保留“Generated loop playing”作为主要状态文案。

## 任务四：界面设计继续优化，可以加入贴图/视觉资产

需要完成：

1. iOS 端继续优化为比赛产品级界面。
2. 可以加入贴图或视觉资产，但要符合跑步、节奏、音乐训练主题。
3. 不要做营销落地页，App 第一屏仍然是可操作界面。
4. 视觉上重点突出：
   - target cadence；
   - current cadence；
   - current track；
   - music source；
   - tempo shift；
   - workout status；
   - Watch sync / standalone status。
5. Watch 端也要优化视觉层级：
   - 大号步频；
   - 小号 workout status；
   - 明确 Play/Pause/End 控制；
   - 连接状态不要抢主视觉。
6. 确保小屏幕文字不重叠、不截断。
7. 使用 SwiftUI 原生能力和 SF Symbols 为主；如果加入图片资产，要保证版权清楚。
8. 如使用贴图，优先使用自制、生成、或明确授权素材，并在 docs 中记录来源。

## 文档和日志要求

1. 每完成一个阶段都更新 CHANGELOG.md。
2. 更新 docs/dev-log.md，写清楚：
   - 完成了什么；
   - 修改了哪些文件；
   - 如何验证；
   - 当前限制；
   - 下一步建议。
3. 更新 README.md：
   - Watch standalone mode；
   - HealthKit / Workout Session；
   - 音乐库权限；
   - 音乐版权和 DRM 限制；
   - 真机验证建议。
4. 如果新增音乐权限、HealthKit 权限、Watch target 配置，要记录在 README。
5. 不要夸大能力：
   - 如果 Apple Music 不能直接变速，就明确写；
   - 如果 HealthKit 实时数据只在真机可靠，就明确写；
   - 如果 BPM 需要用户标注，就明确写。

## 验证要求

1. iOS build 必须通过。
2. watchOS build 必须通过。
3. iOS App 能启动到模拟器。
4. Watch App 能启动到模拟器。
5. Watch App 在没有实时 iPhone 状态时也能显示独立运行界面。
6. 验证 HealthKit 权限路径不会崩。
7. 验证 workout start / pause / resume / end 状态流转。
8. 验证音乐库权限拒绝时 UI 有清楚 fallback。
9. 验证推荐规则没有被破坏：
   - 仍然只做 1:1 BPM；
   - 仍然限制 +/-10%；
   - 不出现 double-time / half-time；
   - 不推荐无 BPM 且未手动标注的曲目。
10. 截图验证：
   - iOS 主界面；
   - iOS 音乐库/权限或曲目匹配界面；
   - iOS workout / Watch sync 状态；
   - Watch standalone 主界面；
   - Watch workout running 状态。
11. 如果某些功能只能真机验证，在 dev-log 中明确写出模拟器限制和真机验证步骤。

## Git 要求

1. 完成后查看 git status 和 git diff，确认没有无关改动。
2. 创建清晰 commit，例如：
   “Add watch standalone workouts and music library matching”
3. push 到 origin/main。
4. 最终回复中说明：
   - 完成内容；
   - 验证结果；
   - 截图路径；
   - commit hash；
   - 是否已 push；
   - 仍然存在的限制。
