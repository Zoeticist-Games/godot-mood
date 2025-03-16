# meta-name: Script with Regions
# meta-description: A generic script that lays out regions to help you organize your code.
# meta-default: true
# meta-space-indent: 4

class_name _CLASS_ extends _BASE_

#region Constants
## put your const vars here.
#endregion

#region Public Variables
## put your @exports here.
##
## then put your var foo, var bar (variables you might touch from elsewhere) here.
#endregion

#region Private Variables
## put variables you won't touch here, prefixed by an underscore (`var _foo`).
#endregion

#region Signals
## put your signal definitions here.
#endregion

#region Overrides
## virtual override methods here, e.g.
## _init, _ready
## _process, _physics_process
## _enter_tree, _exit_tree
#endregion

#region Public Methods
## put your methods here.
#endregion

#region Private Methods
## put methods you use only internally here, prefixed with an underscore.
#endregion

#region Signal Hooks
## put methods used as responses to signals here.
## we don't put #endregion here because this is the last block and when we use the
## UI to add signal hooks they always get concatenated at the end of the file.
