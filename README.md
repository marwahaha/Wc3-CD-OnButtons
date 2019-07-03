# Wc3-CD-OnButtons

This is a Lua code project for warcraft 3 with the goal to display the remaining cooldown of abilities on the buttons in the ui as number.

Each Button gains one Text overlay which is a TEXT frame created by fdfs in the fdf folder.
Casted abilities are saved for the unit in tables. When that unit is selected the cooldown of that ability is checked if it is > 0 update the shown text.

Currently one has to call function UpdateUnitSpellPos(caster) to calculate the positions the abilties take. That has to be done every time an ability that takes an command button is gained.

Currently the converting x/y to button can be wrong, if the choosen x y position of the ability colides with another ability on the same unit. At least that was the case for thunder clap and warstomp on one unit.
