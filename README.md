# grandMA3 Grid Mover

## 🧩 Introduction

**Grid Mover** is a simple grandMA3 plugin that allows you to easily move fixtures within the **Selection Grid**.

## ⚙️ Features

- Move fixtures along a selected axis
- Choose between **Relative** or **Absolute** positioning
- Create macro shortcuts

## 🛠️ How It Works

### 1. Fixture Selection

Before using the plugin, select one or more fixtures in the **Selection Grid**.

> 💡 If you're in **Setup Mode**, you can also move only a specific portion of the selected fixtures.

### 2. Plugin Parameters

When you run the plugin, you can configure the following parameters:

- **Value**  
  The amount or position to which the fixtures will be moved.

- **Axis**  
  The axis along which the movement occurs (`X`, `Y`, or `Z`).

- **Mode**  
  - `Relative`: The value is added to the current position on the selected Axis.
  - `Absolute`: The fixtures are moved to the exact position on the selected Axis.

## 🧱 Macro Generation

When generating macros:

- The current plugin configuration (from the main menu) is used.
- Two macros are always created:
  - One for a **positive** value
  - One for a **negative** value
- The plugin **will not overwrite** existing macros.
- Macros are stored in the **next available pool slot**.

---

Tested in version 2.2.5.0 and above.
