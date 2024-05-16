################################################################################
# Filename: top.tcl
# Author: TIAN Fengshi
# Email: fengshi.tian@connect.ust.hk
# Affiliation: Hong Kong University of Science and Technology
# ------------------------------------------------------------------------------
#
# This file autmates the essential flow for running the place & route of the
# design_top. The P&R flow is based on the EDI 13.1 official workshop and use the
# PDK of Nangate FreePDK 45nm standard cell.
################################################################################

################################################################################
# Step 0: design import
################################################################################
# Synthesized verilog netlist from Design Compiler
set init_verilog "../syn/results/design_top.mapped.v"
# MMC script: corner settings of PDK library
set init_mmmc_file "scripts/mmc2.view"
# LEF file import: abstract view of layout
set init_lef_file "/afs/ee.ust.hk/sun4x_56/usr/eelocal/tsmc_icdc/tsmc180/tsmc180_MS_RF_G/SC/tcb018g3d3/Rev280a/Back_End/lef/tcb018g3d3_280a/lef/tcb018g3d3_6lm.lef"
# Power and ground net name
set init_pwr_net VDD
set init_gnd_net VSS

init_design

# Here we use the TSMC180nm, thereby the process node is set to be 180
setDesignMode -process 180

################################################################################
# Step 1: floorplan
# It will configure the core utilization ratio, module aspect ratio,
# IO pin location.
# Since we do not have the MACRO and our design is very simple, the floorplan is
# automatically handled by the tools. No human interaction is involved, like
# specifying the memory location and placing halo provided in the EDI workshop.
################################################################################
# Distance to IO boundary: 80 um
floorPlan -d 560 560 80 80 80 80

# Load IO assignment file: design_top.ioc
# It specifies the relative location of module pins and on which metal layer you
# are preferred to place your module pins
loadIoFile "scripts/design_top.ioc" -noAdjustDieSize
# Save the checkpoint for floorplan
saveDesign db/design_top_floorplan.enc

################################################################################
# Step 2: power plan
# It mainly defines the power ring and power stripe
# Depending on the different technology node, here FreePDK 45nm has 10 metal
# layers. We are using the top metal (M9 & M10 for power rail).
################################################################################
# Define the global nets for power and ground
globalNetConnect VDD -type pgpin -pin VDD -inst * -override -verbose -netlistOverride
globalNetConnect VSS -type pgpin -pin VSS -inst * -override -verbose -netlistOverride
globalNetConnect VDD -type tiehi -inst * -override -verbose
globalNetConnect VSS -type tielo -inst * -override -verbose
globalNetConnect VDD -type net -net VDD -override -verbose
globalNetConnect VSS -type net -net VSS -override -verbose

# Add power ring: use top metals (M9 & M10) for power ring and set the ring
# width to be 1.5 and spacing to be 0.9
addRing -center 1 -type core_rings -width 20 -spacing 15 -nets {VDD VSS} \
        -layer {bottom METAL3 top METAL3 right METAL4 left METAL4} -follow io

# Add power stripe: use vertical top metal for power stripe (M10). The width is
# set to be 1.25 and spacing to be 0.9. There is only 1 set of power stripe
# starting from the left offset 20.0 (roughly middle of the design_top module)
setAddStripeMode -stacked_via_top_layer METAL4 -stacked_via_bottom_layer METAL3
addStripe -nets {VDD VSS} -layer METAL4 -direction vertical -width 20 -spacing 15 -set_to_set_distance 80 -start_from bottom -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit METAL4 -padcore_ring_bottom_layer_limit METAL5 -block_ring_top_layer_limit METAL4 -block_ring_bottom_layer_limit METAL3 -use_wire_group 0 -snap_wire_center_to_grid None


# Special routing: connect the power and ground net to the standard cell rows
# with layer range: M1 - M10
sroute -connect corePin -nets {VDD VSS} -layerChangeRange {METAL1 METAL5} -blockPinTarget nearestTarget -allowJogging 1 -crossoverViaLayerRange {METAL1 METAL5} -allowLayerChange 1 -targetViaLayerRange {METAL1 METAL5}


# Save the checkpoint for power plan
saveDesign db/design_top_powerplan.enc

################################################################################
# Step 3. placement
# Run the placement to place the standard cell into the row. Disable any scan
# chain since we do not consider scan chain for DFT.
# Optimize the design at the phase of preCTS.
################################################################################
# Setup the placement mode: turn off the reorder scan connection
setPlaceMode -reset
setPlaceMode -reorderScan 0
# Do the placement
placeDesign

# Set RC extraction mode: Pre-Route
setExtractRCMode -engine preRoute

# Optimize the design after placement
optDesign -preCTS -outDir "reports/preCTSTimingReports"

# Save the checkpoint for placement
saveDesign db/design_top_place.enc

################################################################################
# Step 4. Clock tree synthesize (CTS)
# Generate the clock tree specification. Optimize the design at the CTS phase.
################################################################################

# CTS Engine in Innovus CCOpt
setCTSMode -engine ccopt

# Create clock tree specfication
set_ccopt_property buffer_cells { CKBD16 CKBD8 }
set_ccopt_property use_inverters auto

# Config CTS Engine
setCCOptMode -cts_opt_type full
create_ccopt_clock_tree_spec

# Perform CTS
ccopt_design

# # Set CTS engine: ck
# setCTSMode -engine ck

# # Create clock tree specfication file: "Clock.ctstch"
# # The clock tree buffer includes 3 buffers: CLKBUF_X1, CLKBUF_X2, CLKBUF_X3
# # The clock tree buffer is PDK-dependent
# createClockTreeSpec -bufferList {CLKBUF_X1 CLKBUF_X2 CLKBUF_X3} -file \
#                     Clock.ctstch


# # Perform CTS
# clockDesign -specFile Clock.ctstch -outDir clock_report -fixedInstBeforeCTS \
#             -updateIoLatency

# Run post-CTS optimization
setAnalysisMode -analysisType onChipVariation
setAnalysisMode -cppr both
optDesign -postCTS -outDir "reports/postCTSTimingReports"
optDesign -postCTS -hold -outDir "reports/postCTSTimingReports"

# Save the checkpoint for CTS
saveDesign db/design_top_cts.enc

################################################################################
# Step 6. Nano Routing
# Run nano routing for the design.
################################################################################
# Run nano routing
setNanoRouteMode -quiet -timingEngine {}
setNanoRouteMode -quiet -routeWithTimingDriven 1
setNanoRouteMode -quiet -routeWithSiDriven 1
setNanoRouteMode -quiet -routeWithSiPostRouteFix 0
setNanoRouteMode -quiet -routeTopRoutingLayer default
setNanoRouteMode -quiet -routeBottomRoutingLayer default
setNanoRouteMode -quiet -drouteEndIteration default
setNanoRouteMode -quiet -routeWithTimingDriven true
setNanoRouteMode -quiet -routeWithSiDriven true
routeDesign -globalDetail

# Run post-route timing and SI optimization
setExtractRCMode -engine postRoute
setExtractRCMode -effortLevel medium
setDelayCalMode -engine default -SIAware true
optDesign -postRoute -outDir "reports/postRouteTimingReports"
optDesign -postRoute -hold -outDir "reports/postRouteTimingReports"

# Run timing analysis for signoff
# Enable either section bellowed
# ------------------------------------------------------------------------------
# Without QRC license or QRC
# ------------------------------------------------------------------------------
#setDelayCalMode -SIAware false
#setDelayCalMode -engine signalStorm
#setExtractRCMode -effortLevel medium
#timeDesign -postRoute -si -outDir "reports/signoffTimingReports"
#timeDesign -postRoute -si -hold -outDir "reports/signoffTimingReports"
# ------------------------------------------------------------------------------
# With QRC license and QRC installed
# Make sure the Cadence EXT (i.e. QRC) is installed
# On UST server: source /usr/eelocal/cadence/ext191/.cshrc
# ------------------------------------------------------------------------------
setDelayCalMode -SIAware false
setDelayCalMode -engine AAE
timeDesign -signoff -si -outDir "reports/signoffTimingReports"
timeDesign -signoff -si -hold -outDir "reports/signoffTimingReports"

# Add filler: FILLCELL_X32, X16, X8, X4, X2, X1
addFiller -cell {FILL64 FILL32 FILL16 FILL8 FILL4 FILL3 FILL2 FILL1} -doDRC true -fitGap -prefix FILL_ -diffCellViol true

# Save the checkpoint for post route
saveDesign db/design_top_postroute.enc

################################################################################
# Step 7. Exports designs into different formats, including
# - spef file
# - sdf file
# - netlist file
# - gds file
################################################################################
# ------------------------------------------------------------------------------
# Step 7a. Exports useful reports
# ------------------------------------------------------------------------------
# Reports of Geometry and Connectivity (DRC)
verifyGeometry -report reports/design_top.geometry.rpt
verifyConnectivity -type all -report reports/design_top.connectivity.rpt

# Summary reports: html to be browsed, including total area breakdown
summaryReport -outdir reports/summaryReport

# Area report: only report total standard cells area (excluding fillers)
report_area -out_file reports/design_top.routed.area.rpt

# Power report
report_power -outfile reports/design_top.routed.power.rpt

# Setup Timing Report
report_timing -machine_readable -max_paths 100 -max_slack 100.0 -min_slack -100.0 -late > design_top_setup.mtarpt

# Hold Timing Report
report_timing -machine_readable -max_paths 100 -max_slack 100.0 -min_slack -100.0 -early > design_top_hold.mtarpt

# ------------------------------------------------------------------------------
# Step 7b. Exports the design
# ------------------------------------------------------------------------------
# SPEF file: parastic data of wires
rcOut -spef results/design_top.spef -rc_corner rc_worst

# SDF file: delay files for gates and wires
write_sdf results/design_top.sdf

# *.v: verilog netlist file
saveNetlist results/design_top.routed.v

# *.gds: GDS file
streamOut results/design_top.gds -mapFile streamOut.map \
          -merge {/afs/ee.ust.hk/sun4x_56/usr/eelocal/tsmc_icdc/tsmc180/tsmc180_MS_RF_G/SC/tcb018g3d3/Rev280a/Back_End/gds/tcb018g3d3_280a/tcb018g3d3.gds} \
          -stripes 1 -units 10000 -mode ALL
