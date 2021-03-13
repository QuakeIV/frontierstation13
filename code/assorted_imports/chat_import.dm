
#define CHAT_LAYER 12.0001 // Do not insert layers between these two values
#define CHAT_LAYER_MAX 12.9999

#define QDELING(X) (X.gc_destroyed)
#define QDELETED(X) (!X || QDELING(X))

#define APPEARANCE_UI_IGNORE_ALPHA RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|RESET_ALPHA


// /client/script = {"<style>
//.center { text-align: center; }
//.maptext { text-align: center; font-family: 'Small Fonts'; font-size: 7px; -dm-text-outline: 1px black; color: white; line-height: 1.1; }
//</style>"}

//.menutext { font-size: 11px; -dm-text-outline: 0.5px black; color: white; line-height: 1.1; }
//.small, .italics { font-size: 6px; }
//.big, .reallybig, .extremelybig { font-size: 8px; }
//.yell { font-weight: bold; }
//.command_headset { font-weight: bold; font-size: 8px; }