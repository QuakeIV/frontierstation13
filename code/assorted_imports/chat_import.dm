
#define CHAT_LAYER 12.0001 // Do not insert layers between these two values
#define CHAT_LAYER_MAX 12.9999

#define QDELING(X) (X.gc_destroyed)
#define QDELETED(X) (!X || QDELING(X))

#define APPEARANCE_UI_IGNORE_ALPHA RESET_COLOR|RESET_TRANSFORM|NO_CLIENT_COLOR|RESET_ALPHA