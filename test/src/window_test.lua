-- The dialog's registry entry as the Start menu reads it, the shell's
-- picture the entry names found by the shell, the process running the
-- definition, and a shot (test/shots/run.png) drawn by the shell's own
-- renderer — evidence for the eye, next to the checks for the machine.
local test = require("test")
local gfx = require("gfx")
local fs = require("fs")
local registry = require("registry")
local app = require("app")
local ui = require("ui")
local render = require("render")
local rasters = require("rasters")
local images = require("images")
local window = require("window")

local definition = window.definition

-- The client size of the entry's 50×10 outer size minus the frame, and the
-- cell of the owner's terminal — the one the live composer in run_test uses.
-- The SDK rounds `size_px` to the nearest whole cell: at 8 px the 32 px icon
-- gets four cells and is drawn; at a 10 px cell it would get three (30 px)
-- and the renderer would leave it out — a matter of the shell's SDK, which
-- this dialog inherits unchanged.
local CLIENT = {w = 48, h = 7}
local CELL = {w = 8, h = 18}

local function face_font(): any
    local files = assert(fs.get("app:system_fonts"))
    return assert(gfx.font(assert(files:readfile("LiberationSans-Regular.ttf")), {size = 13, smooth = true}))
end

-- A context of the client size with a `watch` that records the channel the
-- dialog asked to watch; `pixels` picks the renderer the plan rounds for.
local function open(pixels: boolean?): (any, any)
    local context = app.context({width = CLIENT.w, height = CLIENT.h, native = pixels == true,
        cell_w = CELL.w, cell_h = CELL.h})
    local watched: any = {}
    context.watch = function(ch: any) watched[#watched + 1] = ch end
    local state = definition.init("", context)
    return state, context
end

local function define_tests()
    test.describe("Run window", function()
        test.it("is a dialog at the root of Start with the shell's picture at both sizes", function()
            local entry = assert(registry.get("windows.run:window"))
            local meta: any = entry.meta
            test.eq(meta.type, "tui_desktop.window")
            test.eq(meta.title, "Run…", "the menu item carries the ellipsis")
            test.eq(meta.group, "", "an explicit empty group is the root of Start, not Programs")
            test.is_true(meta.in_menu, "the root item is in the menu")
            test.eq(meta.window_type, "dialog")
            test.is_false(meta.resizable, "a dialog keeps its size")
            test.eq(tostring(meta.width) .. "x" .. tostring(meta.height), "50x10")
            test.eq(meta.image, "run", "the picture is the shell's own")
            test.eq(meta.pixel_render .. "|" .. meta.pixel_state, "windows.shell.sdk:render|windows.run:window")
            for _, size in ipairs({32, 16}) do
                local picture, why = images.get(meta.image, size)
                test.not_nil(picture, "run@" .. tostring(size) .. ": " .. tostring(why))
            end
            local missing, reason = images.get("windows.run:images/nothing", 16)
            test.is_nil(missing)
            test.not_nil(reason, "a missing picture is refused with a reason, not drawn as nothing")
        end)

        test.it("runs the definition: a fresh state, the tree, the answers, Esc closes", function()
            local state, context = open(false)
            test.eq(state.text, "")
            test.is_false(state.pending)
            test.is_false(state.browsing)
            test.eq(definition.title, "Run", "the window title has no ellipsis")
            local tree = definition.view(state, context)
            test.is_nil(ui.problem(tree), "the tree lays out")
            local plan = ui.plan(tree, CLIENT.w, CLIENT.h, context.interaction)
            test.not_nil(plan.by_id.command)
            test.not_nil(plan.by_id.ok)
            test.not_nil(plan.by_id.cancel)
            test.not_nil(plan.by_id.browse)
            test.is_true(definition.update(state, {type = "change", id = "command", value = "top"}, context) ~= false)
            test.eq(state.text, "top")
            test.is_false(definition.update(state, {type = "key", key_type = "runes", key = "x"}, context),
                "a stray key changes nothing")
            -- `app.dispatch` runs one action the way the loop does: an Esc that
            -- `update` did not take closes the window (`close_on_escape`).
            test.is_true(definition.close_on_escape)
            app.dispatch(definition, state, context, {type = "key", key_type = "esc"})
            test.is_true(context.closing, "Esc closes the dialog")
        end)

        test.it("draws the dialog with a command typed into test/shots/run.png", function()
            local _, context = open(true)
            local tree = definition.view({text = "claude --resume", pending = false}, context)
            test.is_nil(ui.problem(tree))
            -- The icon has its 32 px at this cell; the shot shows it.
            local plan = ui.plan(tree, CLIENT.w, CLIENT.h, context.interaction, {cell = CELL})
            local picture: any = nil
            for _, item in ipairs(plan.items) do
                if item.node.kind == "image" then picture = item end
            end
            test.not_nil(picture, "the dialog's icon is in the plan")
            test.is_true(picture.rect.w * CELL.w >= 32 and picture.rect.h * CELL.h >= 32, "the icon's cells hold its 32 px")
            local store = rasters.store()
            store.begin()
            local placed = assert(render.placement({id = "run", state_revision = 1, content_state = {sdk = 1, revision = 1,
                ui = tree, interaction = context.interaction}}, {x = 1, y = 1, cols = context.width, rows = context.height},
                CELL, {face = face_font()}, store))
            assert(assert(fs.get("app:shots")):writefile("run.png", assert(placed.raster:encode("png"))))
            test.eq(placed.cols .. "x" .. placed.rows, tostring(context.width) .. "x" .. tostring(context.height))
        end)
    end)
end

local run_cases = test.run_cases(define_tests)
return {run = function(options) return run_cases(options) end}
