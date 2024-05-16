#!/bin/sh
# Call all clean scripts
(cd behav_sim; ./clean);
(cd syn; ./clean);
(cd syn_sim; ./clean);
(cd layout; ./clean);
(cd layout_sim; ./clean);