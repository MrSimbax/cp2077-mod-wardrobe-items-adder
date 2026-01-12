---
name: Bug report
about: Create a bug report
title: ''
labels: bug
assignees: ''

---

Please take your time to fill out this template. I cannot help if you don't provide enough information.

**Bug description**
Write a short and clear description of the bug.

**Context**
- Game version:
- Mod version:
- CET version:
- Codeware version (if installed):
- Are any clothing mods installed? (yes/no):
- Do you have EquipmentEX installed? Make sure you're using the Wardrobe storage option if yes! (yes/no):
- Does the bug reproduce in minimal environment? Minimal means: no other mods installed except Wardrobe Items Adder, CET, and Codeware if applicable. (yes/no/I don't know):

**Reproduction steps**
Provide exact steps (with screenshots if you think they'll be helpful) to reproduce the behaviour.

**Expected behaviour**
A clear and concise description of what you expected to happen.

**Actual behaviour**
A clear and concise description of what actually happened.

**Logs**

Please do the following:

0. (Optional) Remove all other mods except Wardrobe Items Adder, CET, and Codeware if you use it. Skip this step if the issue can't be reproduced with other mods installed.
1. Go to `Advanced Settings` in the mod UI and change `Log Level` setting to `All`.
    - If the UI isn't working this step is optional. Alternatively, open the following file with Notepad or other text editor:  `{Cyberpunk 2077 installation directory}/bin/x64/plugins/cyber_engine_tweaks/mods/wardrobe_items_adder/config.lua` (or `default_config.lua` if `config.lua` is not present), find the line `logLevel = SOMENUMBER` and change the number to `1`, then save the file.
2. Perform the reproduction steps you described earlier.
3. Attach the contents of the following log files:
    - `{Cyberpunk 2077 installation directory}/bin/x64/plugins/cyber_engine_tweaks/scripting.log`
    - `{Cyberpunk 2077 installation directory}/bin/x64/plugins/cyber_engine_tweaks/mods/wardrobe_items_adder/wardrobe_items_adder.log`

**Additional information**
Add any other information about the problem here that you think might be helpful, e.g. additional information not fitting above, steps you've taken to try to debug/fix the issue if any, list of mods you have installed or suspect that could be related to the issue, etc.
