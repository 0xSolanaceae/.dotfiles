
;the valid meterstyles are the following:
;info|dispT = the text to be displayed to the right of the icon (uses the string value of the measure)
;info|percent|dispT = same as above but uses the number value of the measure along with a "%"
;you can add a `text=something` under the section to override this meterstyle

;info|icon|dispI = the icon to be displayed to the left of the text

;you may add custom infos according to the format provided in the example below
;the sections should follow the order and pattern of [m<info>Disp],[<info>Disp],[<info>]
;if the measure is a system info monitor, you may add `updatedivider=-1` and `group=rate` under the [m<info>Disp]
;this makes it update only every #updateR# seconds (2 by default)
;the variable `<info>Disp=1` should be declared under [variables] to show/hide the info
;the variable `<info>Icon` is the unicode value of the icon to be used
;you may use a site like https://fontdrop.info/ to view the "icomooccin" icon file in the skin's @resources\fonts folder
;if you do everything correctly, and hit `refresh` on the settings page, the toggle should show up in the settings
;a maximum of 5 additional infos are supported