# Copyright © Telecom Paris
# Copyright © Renaud Pacalet (renaud.pacalet@telecom-paris.fr)
#
# This file must be used under the terms of the CeCILL. This source
# file is licensed as described in the file COPYING, which you should
# have received as part of this distribution. The terms are also
# available at:
# https://cecill.info/licences/Licence_CeCILL_V2.1-en.html

axi_memory-lib		:= common
axi_memory_sim-lib	:= common
axi_pkg-lib			:= common
axi_sim_pkg-lib		:= common
fifo-lib			:= common
fifo_pkg-lib		:= common
fifo_sim-lib		:= common
rnd_pkg-lib			:= common
utils_pkg-lib		:= common

axi_memory: axi_pkg
axi_memory_sim: utils_pkg axi_pkg axi_memory
axi_sim_pkg: axi_pkg
fifo_sim: rnd_pkg utils_pkg fifo_pkg fifo

# vim: set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab textwidth=0:
