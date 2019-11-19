#!/bin/bash -f

# svn keywords:
# $Rev: 317 $: Revision of last commit
# $Author: genser $: Author of last commit
# $Date: 2009-04-27 16:50:27 -0500 (Mon, 27 Apr 2009) $: Date of last commit

#-----------------------------------------------------------------------
# This script is run by fix_tool_description.
#-----------------------------------------------------------------------

# TODO: Move this to CMS-specific directory, preparing for move out of perfdb.

if ! type -p scramv1 >&/dev/null
then
    source /uscmst1/prod/sw/cms/bashrc prod
fi

scramv1 arch

exit $?

