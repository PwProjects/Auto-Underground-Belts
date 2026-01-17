# Auto-Underground Belts (Factorio Mod)

Auto-Underground-Belts is a quality-of-life mod. It automatically converts transport belts into underground jumps when dragging them across brick or concrete tiles.

## 🛠 How it Works

When you drag a belt:
1. The mod monitors the tiles beneath your cursor.
2. If you start dragging a belt on a non-concrete tile and run over a patch of concrete, the mod will avoid the patch by surrounding it with underground belts as if it were a building entity.
3. If you start dragging a belt on top of concrete, the belts will behave normally.
4. If the width of the concrete patch exceeds the maximum distance of the underground belt, the belt will also behave normally.
5. Belts will convert to base-game behavior if you attempt to belt over an entity or obstacle that exists on top of the concrete. Undergrounds wil placed around the entity, not the concrete.

## ⚙️ Configuration

 All settings can be found in **Settings > Mod Settings > Map**

 - Use the master toggle to completely enable or disable the mod
 - Use the tile toggles to individually disable auto-underground belting for specific tiles:
  - Stone path
  - Concrete
  - Refined Concrete
  - Hazard Concrete Left
  - Hazard Concrete Right
  - Refined Hazard Concrete Left
  - Refined Hazard Concrete Right