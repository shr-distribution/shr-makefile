# INHERIT like this doesn't work anymore, if you want to use 
# srctree, gitver or gitpkgv features you have to alter the recipe itself
# INHERIT_append_pn-libphone-ui-shr = "srctree gitpkgv"
# SRCREV_pn-libphone-ui-shr = "${GITSHA}"

S_pn-libphone-ui-shr = "/OE/projects/${PN}"
SRCPV_pn-libphone-ui-shr = "1+LOCAL"

#enable this if you have patches in SRC_URI and it's git:// 
#otherwise default will overwrite your local changes when applying patches
#PATCHTOOL_pn-libphone-ui-shr = "patch"
#other option is to empty SRC_URI
#SRC_URI_pn-libphone-ui-shr = ""
#but then be sure you have also SRCPV set to something
#SRCREV_pn-libphone-ui-shr = "LOCAL"
#LOCALCOUNT_pn-libphone-ui-shr = "1"
#SRCPV_pn-libphone-ui-shr = "${LOCALCOUNT}+${SRCREV}"
