import os
import subprocess
import time
from pathlib import Path

import addon_utils
import bpy


bl_info = {
    "name": "Refresh Flowcell Item Tab",
    "author": "OpenAI Codex",
    "version": (1, 0, 0),
    "blender": (5, 0, 0),
    "location": "View3D > Sidebar > Item",
    "description": "Add an Item-tab button that reloads the FlowCell addon and restarts the FlowCell desktop UI.",
    "category": "Object",
}


FLOWCELL_MODULE_FALLBACKS = ("flowcell_actions", "flowcell")
FLOWCELL_DISPLAY_NAMES = {"flowcell", "blender organizer"}
FLOWCELL_ROOT_ENV = "FLOWCELL_ROOT"
FLOWCELL_WINDOW_TITLE = "FlowCell"
FLOWCELL_ROOT_HINTS = (
    Path(r"D:\Dev\workspace\Codex\flowcell"),
)


def _find_flowcell_module_name() -> str:
    for module in addon_utils.modules(refresh=False):
        module_name = str(getattr(module, "__name__", "") or "").strip()
        if not module_name or module_name == __name__:
            continue

        display_name = str((getattr(module, "bl_info", {}) or {}).get("name", "")).strip().casefold()
        if display_name in FLOWCELL_DISPLAY_NAMES:
            return module_name

    for module_name in FLOWCELL_MODULE_FALLBACKS:
        if module_name == __name__:
            continue
        if any(str(getattr(module, "__name__", "") or "") == module_name for module in addon_utils.modules(refresh=False)):
            return module_name

    return ""


def _resolve_flowcell_root() -> Path | None:
    candidates: list[Path] = []

    env_root = os.environ.get(FLOWCELL_ROOT_ENV, "").strip()
    if env_root:
        candidates.append(Path(env_root).expanduser())

    script_path = Path(__file__).resolve()
    for parent in (script_path.parent, *script_path.parents):
        candidates.append(parent)

    candidates.extend(FLOWCELL_ROOT_HINTS)

    seen: set[str] = set()
    for candidate in candidates:
        candidate_key = str(candidate).casefold()
        if candidate_key in seen:
            continue
        seen.add(candidate_key)

        if (candidate / "run_hidden.vbs").is_file() and (candidate / "FlowCell" / "run_hidden.vbs").is_file():
            return candidate

    return None


def _restart_flowcell_desktop() -> str:
    flowcell_root = _resolve_flowcell_root()
    if flowcell_root is None:
        raise RuntimeError(
            "Could not find the FlowCell workspace root. Set FLOWCELL_ROOT or install this script from the FlowCell repo."
        )

    launcher_path = flowcell_root / "run_hidden.vbs"
    if not launcher_path.is_file():
        raise RuntimeError(f"FlowCell launcher was not found: {launcher_path}")

    subprocess.run(
        [
            "taskkill",
            "/FI",
            "IMAGENAME eq powershell.exe",
            "/FI",
            f"WINDOWTITLE eq {FLOWCELL_WINDOW_TITLE}",
            "/T",
            "/F",
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    time.sleep(0.35)
    subprocess.Popen(
        ["wscript.exe", str(launcher_path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        stdin=subprocess.DEVNULL,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    return "Restarted the FlowCell desktop UI."


def _reload_flowcell_addon() -> str:
    module_name = _find_flowcell_module_name()
    if not module_name:
        raise RuntimeError("Could not find the installed FlowCell addon to reload.")

    _, is_enabled = addon_utils.check(module_name)
    if is_enabled:
        addon_utils.disable(module_name, default_set=False)

    addon_utils.enable(module_name, default_set=False)
    return f"Reloaded Blender addon '{module_name}'."


class VIEW3D_OT_refresh_flowcell(bpy.types.Operator):
    bl_idname = "view3d.refresh_flowcell"
    bl_label = "refresh flowcell"
    bl_description = "Disable and re-enable the FlowCell addon, then restart the FlowCell desktop UI"
    bl_options = {"REGISTER"}

    def execute(self, context: bpy.types.Context):
        del context
        try:
            addon_message = _reload_flowcell_addon()
            desktop_message = _restart_flowcell_desktop()
        except Exception as exc:
            self.report({"ERROR"}, str(exc))
            return {"CANCELLED"}

        self.report({"INFO"}, f"{addon_message} {desktop_message}")
        return {"FINISHED"}


class VIEW3D_PT_refresh_flowcell_item_tab(bpy.types.Panel):
    bl_label = "FlowCell"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Item"

    def draw(self, context: bpy.types.Context):
        del context
        self.layout.operator(VIEW3D_OT_refresh_flowcell.bl_idname, icon="FILE_REFRESH")


CLASSES = (
    VIEW3D_OT_refresh_flowcell,
    VIEW3D_PT_refresh_flowcell_item_tab,
)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)


def unregister():
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == "__main__":
    register()
