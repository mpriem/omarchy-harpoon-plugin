#!/usr/bin/env python3
"""Disposable live test: scratchpad placeholder -> tiled window -> swap back.

Runs on an unused workspace and closes only the test's own windows.
"""
import json
import argparse
from pathlib import Path
import shlex
import subprocess
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]


def query(name):
    return json.loads(subprocess.check_output(["hyprctl", "-j", name], text=True))


def dispatch(expression):
    result = subprocess.check_output(["hyprctl", "dispatch", expression], text=True).strip()
    if result != "ok":
        raise RuntimeError(result)


def selector(w):
    return json.dumps("address:" + w["address"])


def wait_for(predicate):
    deadline = time.monotonic() + 8
    while time.monotonic() < deadline:
        result = predicate()
        if result:
            return result
        time.sleep(0.05)
    raise RuntimeError("Timed out waiting for test window")


def current(w):
    return next((c for c in query("clients") if c["address"] == w["address"]), None)


def launch(title, workspace, floating=False):
    command = "exec env " + shlex.quote("HARPOON_PLACEHOLDER_TITLE=" + title)
    command += " quickshell -p " + shlex.quote(str(ROOT / "HarpoonPlaceholder.qml"))
    dispatch('hl.dsp.exec_cmd(' + json.dumps(command) + ', {workspace = '
             + json.dumps(str(workspace) + " silent") + ', float = '
             + str(floating).lower() + '})')
    return wait_for(lambda: next((c for c in query("clients") if c["title"] == title), None))


def geometry(w):
    return {k: w[k] for k in ("at", "size", "floating", "workspace")}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--layout", choices=("dwindle", "scrolling"), default="dwindle")
    parser.add_argument("--integrated", action="store_true", help="Exercise the installed Harpoon backend")
    args = parser.parse_args()
    state_path = Path.home() / ".local/state/omarchy/harpoon/list.json"
    slot = None
    if args.integrated:
        slots = json.loads(state_path.read_text())["slots"]
        slot = next((i + 1 for i, entry in enumerate(slots) if not entry), None)
        if slot is None:
            raise RuntimeError("No empty bookmark slot available for the test")
    previous = query("activewindow")
    previous_ws = query("activeworkspace")["id"]
    used = {w["id"] for w in query("workspaces")}
    workspace = next(n for n in range(901, 998) if n not in used)
    token = "Harpoon-test-" + uuid.uuid4().hex[:10]
    windows = []
    try:
        subprocess.run(["hyprctl", "eval", f'hl.workspace_rule({{workspace = "{workspace}", layout = "{args.layout}"}})'], check=True, capture_output=True)
        dispatch(f'hl.dsp.focus({{workspace = {workspace}}})')
        assert query("activeworkspace")["tiledLayout"] == args.layout
        for suffix in ("A", "B", "C"):
            windows.append(launch(token + suffix, workspace))
        # In dwindle A is beside the entire B/C subtree: the case the old
        # neighbour-based restore could not reconstruct.
        original = windows[0]
        dispatch(f'hl.dsp.focus({{window = {selector(original)}}})')
        time.sleep(0.5)
        before = {w["address"]: geometry(current(w)) for w in windows}
        if args.integrated:
            dispatch(f'Harpoon.add({slot})')
            dispatch(f'Harpoon.jump({slot})')
            def reserved_entry():
                entry = json.loads(state_path.read_text())["slots"][slot - 1]
                return entry if entry and entry.get("overlaid") else None
            entry = wait_for(reserved_entry)
            placeholder = current({"address": entry["placeholder"]})
            windows.append(placeholder)
            time.sleep(0.5)
            assert geometry(current(placeholder)) == before[original["address"]], "Reservation changed size"
            for w in windows[1:3]:
                assert geometry(current(w)) == before[w["address"]], "Neighbour moved"
            dispatch(f'Harpoon.restore({slot})')
            wait_for(lambda: current(placeholder) is None)
            time.sleep(0.5)
            for w in windows[:3]:
                assert geometry(current(w)) == before[w["address"]], ("restore differs", before, geometry(current(w)))
            dispatch(f'Harpoon.delete({slot})')
            # Closing the reservation falls back to ordinary re-tiling.
            dispatch(f'Harpoon.add({slot})')
            dispatch(f'Harpoon.jump({slot})')
            entry = wait_for(reserved_entry)
            placeholder = current({"address": entry["placeholder"]})
            dispatch(f'hl.dsp.window.close({{window = {selector(placeholder)}}})')
            wait_for(lambda: not json.loads(state_path.read_text())["slots"][slot - 1].get("placeholder"))
            dispatch(f'Harpoon.restore({slot})')
            assert not current(original)["floating"], "Closed reservation did not fall back to tiling"
            dispatch(f'Harpoon.delete({slot})')
            # Closing the real window must also remove its reservation.
            dispatch(f'Harpoon.add({slot})')
            dispatch(f'Harpoon.jump({slot})')
            entry = wait_for(reserved_entry)
            placeholder = current({"address": entry["placeholder"]})
            dispatch(f'hl.dsp.window.close({{window = {selector(original)}}})')
            wait_for(lambda: current(placeholder) is None)
            wait_for(lambda: not json.loads(state_path.read_text())["slots"][slot - 1])
            print(f"PASS ({args.layout}, integrated Harpoon): exact geometry, missing-placeholder fallback, closed-window cleanup")
            return
        placeholder = launch(token + "P", "special:harpoon-test")
        windows.append(placeholder)
        assert not placeholder["floating"] and placeholder["workspace"]["id"] < 0, placeholder
        dispatch(f'hl.dsp.window.swap({{window = {selector(original)}, target = {selector(placeholder)}}})')
        time.sleep(0.5)
        reserved = geometry(current(placeholder))
        assert reserved == before[original["address"]], ("reservation differs", reserved, before)
        for w in windows[1:3]:
            assert geometry(current(w)) == before[w["address"]], "Neighbour moved"
        dispatch(f'hl.dsp.window.float({{window = {selector(original)}, action = "toggle"}})')
        dispatch(f'hl.dsp.window.move({{window = {selector(original)}, workspace = {workspace}, follow = false}})')
        dispatch(f'hl.dsp.window.move({{window = {selector(original)}, workspace = "special:harpoon-test", follow = false}})')
        dispatch(f'hl.dsp.window.float({{window = {selector(original)}, action = "toggle"}})')
        dispatch(f'hl.dsp.window.swap({{window = {selector(original)}, target = {selector(placeholder)}}})')
        dispatch(f'hl.dsp.window.close({{window = {selector(placeholder)}}})')
        wait_for(lambda: current(placeholder) is None)
        time.sleep(0.5)
        for w in windows[:3]:
            assert geometry(current(w)) == before[w["address"]], ("restore differs", before, geometry(current(w)))
        print(f"PASS ({args.layout}): scratchpad swap preserves all three windows' exact geometry and restores it")
    finally:
        if args.integrated and windows:
            entry = json.loads(state_path.read_text())["slots"][slot - 1]
            if entry and entry["address"] in [w["address"] for w in windows]:
                dispatch(f'Harpoon.delete({slot})')
        for w in query("clients"):
            if w["title"].startswith(token):
                dispatch(f'hl.dsp.window.close({{window = {selector(w)}}})')
        if previous and current(previous):
            dispatch(f'hl.dsp.focus({{window = {selector(previous)}}})')
        else:
            dispatch(f'hl.dsp.focus({{workspace = {previous_ws}}})')


if __name__ == "__main__":
    main()
