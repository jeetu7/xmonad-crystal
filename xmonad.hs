-- This is the main configuration file

--import XMonad.Hooks.SetCursor
import System.Exit
import System.IO
import XMonad
import XMonad.Actions.CycleWS
import XMonad.Actions.DwmPromote
import XMonad.Actions.GridSelect
import XMonad.Actions.UpdatePointer
import XMonad.Actions.WindowGo
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.Script
import XMonad.Hooks.SetWMName
import XMonad.Layout.Fullscreen
import XMonad.Layout.NoBorders
import XMonad.Layout.ShowWName
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run(spawnPipe)
import Graphics.X11.ExtraTypes.XF86
import XMonad.Util.EZConfig(additionalKeys)
import qualified Data.Map as M
import qualified XMonad.StackSet as W

------------------------------------------------------------------------------
-- Workspace names
myWorkspaces = [" 1:Web ", " 2:Work " , " 3:Extra ", " 4:Music "] ++ map show [5..6]                                                 
------------------------------------------------------------------------------
scratchpads = [ NS "quake" "urxvt -name quake" findQuake manageQuake
              , NS "gvimnotes" "gvim --role notes ~/.notes.txt" findGvim nonFloating
              ]
    where
        findQuake = resource =? "quake"
        manageQuake = customFloating $ W.RationalRect l t w h
            where
                h = 0.4       -- height, 40%
                w = 1         -- width, 100%
                t = 0         -- top edge
                l = 0         -- centered left/right
        findGvim = (stringProperty "WM_WINDOW_ROLE") =? "notes"

myScratchpad = namedScratchpadManageHook scratchpads

------------------------------------------------------------------------------
windowRulesHook = composeAll
    [ className =? "stalonetray"     -->doIgnore
    , className =? "trayer"          -->doIgnore
    , resource =? "grun"             -->doCenterFloat
    , resource =? "vym"              -->doF (W.shift "4")
    , resource =? "gmusicbrowser"    -->doF (W.shift "4")
    , isDialog                       -->doFloat
    , className =? "florence"        -->doFloat
    , className =? "Screenruler"     -->doFloat
    , isFullscreen --> (doF W.focusDown <+> doFullFloat)
    ]

------------------------------------------------------------------------------
myLayout = avoidStruts (
    ThreeColMid 1 (3/100) (1/2) |||
    Tall 1 (3/100) (1/2) |||
    Mirror (Tall 1 (3/100) (1/2)) |||
    tabbed shrinkText tabConfig |||
    Full) |||
    noBorders (fullscreenFull Full)
------------------------------------------------------------------------------
-- Colors and borders
-- Currently based on the ir_black theme.
--
myNormalBorderColor  = "#7c7c7c"
myFocusedBorderColor = "#ffb6b0"

-- Colors for text and backgrounds of each tab when in "Tabbed" layout.
tabConfig = defaultTheme {
    activeBorderColor = "#7C7C7C",
    activeTextColor = "#CEFFAC",
    activeColor = "#000000",
    inactiveBorderColor = "#7C7C7C",
    inactiveTextColor = "#EEEEEE",
    inactiveColor = "#000000"
}

-- Color of current window title in xmobar.
xmobarTitleColor = "#FFB6B0"

-- Color of current workspace in xmobar.
xmobarCurrentWorkspaceColor = "#CEFFAC"

------------------------------------------------------------------------------
myManageHook = manageDocks <+>
               manageHook defaultConfig <+>
               myScratchpad <+>
               windowRulesHook

myLayoutHook = avoidStruts $ showWName (smartBorders (layoutHook defaultConfig))

modm = mod4Mask

------------------------------------------------------------------------------
myConfig = ewmh defaultConfig
        { manageHook = myManageHook
        , layoutHook = myLayoutHook                                            -- Make way for system tray.
        , modMask = modm                                                       -- Make Super key as the main modifier.
        , borderWidth = 2
        , terminal = "urxvt -pe tabbed"
        , normalBorderColor = "#cccccc"
        , focusedBorderColor = "##ff0000"
        , workspaces = myWorkspaces
        , keys = \_ -> M.fromList  crystalKeys                                 -- Add list "crystalKeys" key bindings
        , startupHook =  myStartupHook
	, handleEventHook    = handleEventHook defaultConfig <+> docksEventHook
        , logHook = updatePointer (0.05, 0.95) (1, 1)
        }

------------------------------------------------------------------------------
myStartupHook = do
    --setDefaultCursor 68                                                      -- Presently seems not in the package of Debian
    execScriptHook  "autostart"                                                -- Run  ~/.xmonad/hooks with arg autostart

------------------------------------------------------------------------------
main = do
    xmproc <- spawnPipe "xmobar ~/.xmonad/xmobar.config"
    xmonad  $ myConfig {
      logHook = dynamicLogWithPP $ xmobarPP {
            ppOutput = hPutStrLn xmproc
          , ppTitle = xmobarColor xmobarTitleColor "" . shorten 100
          , ppCurrent = xmobarColor xmobarCurrentWorkspaceColor ""
          , ppSep = "   "
      },
      startupHook = startupHook myConfig >> setWMName "LG3D"               -- For ewmh and setwmname to work together
        }

------------------------------------------------------------------------------
-- This is the list of custom key bindings
crystalKeys =
    [ ((modm .|. shiftMask, xK_l), spawn "xscreensaver-command -lock")         -- Lock the screen
    , ((modm,               xK_grave), namedScratchpadAction scratchpads "quake")
    , ((modm .|. shiftMask, xK_Return), namedScratchpadAction scratchpads "gvimnotes")
    , ((modm,               xK_Scroll_Lock), spawn "~/bin/have_a_break.sh")
    , ((modm,               xK_f), spawn "~/bin/firefox.sh")
    , ((modm,               xK_r), spawn "grun")
    ]
    ++
    -- Workspace keys
    [ ((m .|. modm, k), windows $ f i)
        | (i, k) <- zip myWorkspaces [xK_F1..xK_F12]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]                  -- Move windows to workspaces
    ]
    ++
    -- More workspace keys
    [ ((modm,               xK_Escape), toggleWS' ["NSP"])                     -- Toggle viewed workspace
    , ((modm,               xK_Left), prevWS)                                  -- Go to prev workspace
    , ((modm,               xK_Right), nextWS)                                 -- Go to next workspace
    , ((modm,               xK_Down), prevScreen)                              -- Go to prev screen
    , ((modm,               xK_Up), nextScreen)                                -- Go to next screen
    , ((modm .|. shiftMask, xK_Left), shiftToPrev >> prevWS)                   -- Move window to previous workspace
    , ((modm .|. shiftMask, xK_Down), shiftPrevScreen >> prevScreen)           -- Move window to previous screen
    , ((modm .|. shiftMask, xK_Right), shiftToNext >> nextWS)                  -- Move window to next workspace
    , ((modm .|. shiftMask, xK_Up), shiftNextScreen >> nextScreen)             -- Move window to next screen
    ]
    ++
    -- Pulse volume control keys
    [ ((modm,  xK_8), spawn "~/bin/pulse_control.sh mute")                         -- Mute the pulseaudio controlume
    , ((modm,  xK_9), spawn "~/bin/pulse_control.sh down")                     -- Decrease the pulseaudio controlume
    , ((modm,  xK_0), spawn "~/bin/pulse_control.sh up")                     -- Increase the pulseaudio controlume
    ]
    ++
    [ ((modm,               xK_z), spawn "~/bin/take_xwrits_break.sh")                        -- Sent click to xwrit's window
    , ((modm,               xK_Insert), spawn "~/bin/switch_keyboard_layout_qwerty.sh")       -- Switch to QWERTY
    , ((modm,               xK_Delete), spawn "~/bin/switch_keyboard_layout_colemak.sh")       -- Switch to QWERTY
    , ((0,                  xF86XK_AudioMedia), spawn "xfe")                        -- Open file browser
    ]
    ++
    --  Window settings
    [ ((modm .|. shiftMask, xK_BackSpace), kill)                               -- Kill the focused window
    , ((modm,               xK_Tab), goToSelected defaultGSConfig)
    ]
    ++
    -- Colemak specific changes
    [ ((modm .|. shiftMask, xK_grave), spawn "urxvt -pe tabbed")                          -- spawn terminal
    , ((modm .|. shiftMask, xK_space), sendMessage NextLayout)                 -- next layout
    , ((modm .|. shiftMask, xK_r), refresh)                                    -- resize to correct size
    , ((modm,               xK_n), windows W.focusDown)                        -- move focus; next window
    , ((modm,               xK_e), windows W.focusUp)                          -- move focus; prev. window
    , ((modm,               xK_m), windows W.focusMaster)                      -- focus on master
    , ((modm,               xK_Return), dwmpromote)                            -- swap focused with master/next
    , ((modm .|. shiftMask, xK_n), windows W.swapDown)                         -- swap focused with next window
    , ((modm .|. shiftMask, xK_e), windows W.swapUp)                           -- swap focused with prev. window
    , ((modm,               xK_h), sendMessage Shrink)                         -- shrink master area
    , ((modm,               xK_i), sendMessage Expand)                         -- expand master area
    , ((modm,               xK_t), withFocused $ windows . W.sink)             -- put window back on tiling layer
    , ((modm,               xK_comma), sendMessage (IncMasterN 1))             -- increase number of windows in master pane
    , ((modm,               xK_period), sendMessage (IncMasterN (-1)))         -- decrease number of windows in master pane
    , ((modm,               xK_Pause), spawn "~/bin/blank_screen.sh")         -- blanks the screen
    , ((modm,               xK_b), sendMessage ToggleStruts)                   -- toggle status bar gap, uses ManageDocks
    , ((modm .|. shiftMask, xK_x), io (exitWith ExitSuccess))                  -- exit Xmonad
    , ((modm,               xK_q), broadcastMessage ReleaseResources
                                       >> restart "xmonad" True)               -- restart xmonad
    ]
------------------------------------------------------------------------------

