# Room Katamari (Godot 4.6)

`room-rally` から**塊魂風の部分だけ**を切り出した Godot 4.6 プロジェクトです。
トラックで物を壊すレースゲームから、レース要素を外しました。代わりに、転がる玉に物がくっついて大きくなる仕組みにしています。

## 遊び方

| 操作 | キーボード / パッド | タッチ |
| --- | --- | --- |
| 前進 / 後退 | W・S / ↑・↓ / 左スティック上下（トリガーも可） | 画面のどこかを触ってドラッグ（上下） |
| 旋回（カメラも追従） | A・D / ← → / 左スティック左右 | ドラッグ（左右） |

- 今の大きさで扱える物（tier）に触れると、玉にくっついてスコアが入ります。
- スコアが `tier_thresholds` に届くとレベルが上がり、玉が 1.5 倍に大きくなって、次のサイズの家具も巻き込めるようになります。
- まだ巻き込めない大きな家具はただの障害物です。カメラとの間に入ると半透明になります。

## 元プロジェクトから引き継いだもの / 外したもの

| 元 (room-rally) | このプロジェクト |
| --- | --- |
| `game_manager.gd`（スコア・タイマー・tier 解放） | **そのまま** |
| `prop_spawner.gd`（部屋のレイアウト・小物配置・シェーダーウォームアップ） | **ほぼそのまま**（`Absorbable` を生成） |
| `decor.gd` / `drop_wall.gd` / 部屋・ライト・環境 | **そのまま**（参照先を player に変更） |
| `destructible.gd`（壊れてパーティクル） | `absorbable.gd`：壊さず**玉にくっつく**。遮蔽フェードは継承 |
| `vehicle.gd` + トラックモデル + エンジン/スキッド音・タイヤ痕 | **削除** → `katamari.gd`（転がる RigidBody 玉） |
| `view.gd`（チェイス/俯瞰の切替） | `camera_rig.gd`：玉の後ろに付くチェイスのみ。サイズに合わせて引く |
| `touch_controls.gd`（L/R/GAS/BRK ボタン） | フローティング仮想スティックに置き換え |
| `perf_probe.gd`（診断 HUD） | 削除 |

### 挙動上の変更点

- トラックは見た目だけが大きくなり、当たり判定は半径 0.5 のままでした。玉は**当たり判定ごと**大きくなります。そのため、壁のコリジョンは高さ 60 m の見えない壁にしています（見た目の壁は元のまま 3 m で、近づくと下がります）。
- 巻き込んだ物は玉の表面に貼り付きます。玉が大きくなって完全に埋もれた物と、80 個を超えた古い物は消して負荷を抑えています（`max_stuck`）。
- 画面下に玉の直径を表示します（1 unit = 20 cm 換算）。
- ストレッチモードを `canvas_items` / `expand` にしました。iframe のサイズに関係なく、UI が同じ比率で表示されます。

## 主な調整パラメータ

- `GameManager.game_duration`（既定 60 秒）、`tier_thresholds`
- `Katamari.max_speed` / `turn_speed` / `base_radius` / `max_stuck`、成長率 `GROW_PER_TIER`
- `CameraRig.cam_height` / `cam_back` / `size_exponent`
- `prop_spawner.gd` の `LAYOUT` / `CLUTTER`（`t` = 必要 tier、`h` = 高さ、`s` = 点数、`c` = 個数）

## Web 書き出し（CrazyGames 向け）

`export_presets.cfg` に Web プリセットを入れてあります。

- **Thread Support: OFF**（`variant/thread_support=false`）。CrazyGames は iframe の中で動くため、COOP/COEP ヘッダー（SharedArrayBuffer）を前提にしない single-thread 版にしています。
- Godot 4.6.3 の Web 用エクスポートテンプレートを入れてから、Project → Export → Web で `build/web/` に書き出してください。

## アセット

- 3D モデルと効果音：[Kenney](https://kenney.nl)（CC0）の Furniture Kit / Food Kit / Impact Sounds。元ビルドの pck から取り出して .glb に書き戻したものです。
- エンジン：Godot Engine 4.6（MIT）
