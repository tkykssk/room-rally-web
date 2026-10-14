# Slime Eater（Godot 4.6 ソース）

`room-rally-src/` をベースに、プレイヤーをトラックからスライムに置き換えた別ゲームです。ステージ・ジャーニー・UI・バグ修正は Room Rally と共通で、詳しくは `room-rally-src/README.md` を参照してください。Web 版は `/slime/` で配信しています。

## Room Rally との違い

- **プレイヤー**：`scenes/slime.tscn` / `scripts/slime.gd`（`scenes/vehicle.tscn` と `scripts/vehicle.gd` は削除）。
  - 移動は球を転がす方式ではなく、向いている方向へ速度を直接寄せる方式です（`grip`）。手を離すと約 0.6 秒で止まり、曲がるときに滑りません。最高速度はトラックと同じ（約 7 m/s × 大きさ）です。
  - Space / JUMP ボタンでジャンプします。
  - 体はばねでぷるぷる揺れ、加速・着地・ジャンプでつぶれたり伸びたりします（`shaders/slime.gdshader`）。
- **食べる**：物に触れると、その位置で形を保ったまま体に取り込まれます（`scripts/destructible.gd` の `try_eat`）。
  - 接触面から体の中心へ沈みながら、接触点から侵食するように溶けて消えます（`shaders/prop_dissolve.gdshader`）。溶ける縁はスライムの体の色で光ります。
  - 溶けた分だけ、物の色（面積の大きい上位 3 色）が絵の具の粒として体内に入ります。
- **色の物理演算**（`scripts/slime.gd`）：体内の粒は慣性で揺れ、浮き沈みし、膜で跳ね返り、隣どうしで色がにじみます。色は対数空間で混ぜるので絵の具のように混ざります（黄＋青＝緑）。古い色は約 20 秒で薄れ、最近食べた物の色が強く出ます。
- **HUD**：スコア欄に今の体の色（チップと 16 進コード）を表示します。

## Web 版のビルド

リポジトリ直下のエンジン（`index.js` / `index.wasm`）を共有するので、`.pck` だけ書き出せば足ります（エクスポートテンプレート不要）。

```sh
cd slime-src
godot --headless --import
godot --headless --export-pack "Web (Vercel)" ../slime/index.pck
```

書き出したら `slime/index.html` の `fileSizes` の `"index.pck"` を新しいサイズに更新してください（読み込みバー用）。
