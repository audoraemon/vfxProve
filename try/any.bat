@echo off
rem Everything built on the abilities branch: one try_<name>.bat per power or pair, each a loadout for the real
rem town mission (1-4 picks a slot, LMB casts, Q/E modes, F4 overlay). They call ..	ry.bat; see its header.
rem Give any keys to try your own loadout:  tryny.bat smite ember curfew nova
call "%~dp0..\try.bat" %*
