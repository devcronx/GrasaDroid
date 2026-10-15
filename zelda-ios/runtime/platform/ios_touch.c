// Controles táctiles para iOS - gamepad virtual de SDL3.
// D-pad a la izquierda, botones A/B a la derecha, Start/Select arriba.
#include <SDL3/SDL.h>
#include <stdbool.h>

static SDL_Joystick *vjoy = NULL;
static SDL_JoystickID vjoy_id = 0;

// Regiones táctiles (coordenadas normalizadas 0.0-1.0)
// D-pad: izquierda, abajo
// A/B: derecha, abajo
// Start/Select: arriba centro

typedef struct {
    float x0, y0, x1, y1;  // región normalizada
    int button;            // SDL_GamepadButton
} TouchButton;

// Layout: D-pad (izq), A/B/X/Y (der), Plus/Minus (arriba)
static const TouchButton touch_map[] = {
    // D-pad
    {0.02, 0.65, 0.10, 0.75, SDL_GAMEPAD_BUTTON_DPAD_LEFT},
    {0.10, 0.55, 0.18, 0.65, SDL_GAMEPAD_BUTTON_DPAD_UP},
    {0.18, 0.65, 0.26, 0.75, SDL_GAMEPAD_BUTTON_DPAD_RIGHT},
    {0.10, 0.75, 0.18, 0.85, SDL_GAMEPAD_BUTTON_DPAD_DOWN},
    // Botones acción (derecha)
    {0.82, 0.65, 0.90, 0.75, SDL_GAMEPAD_BUTTON_SOUTH},  // A (B en Switch)
    {0.90, 0.55, 0.98, 0.65, SDL_GAMEPAD_BUTTON_EAST},   // B (A en Switch)
    {0.74, 0.55, 0.82, 0.65, SDL_GAMEPAD_BUTTON_WEST},   // Y
    {0.82, 0.45, 0.90, 0.55, SDL_GAMEPAD_BUTTON_NORTH},  // X
    // Start/Select
    {0.45, 0.02, 0.55, 0.08, SDL_GAMEPAD_BUTTON_START},  // Plus
    {0.35, 0.02, 0.45, 0.08, SDL_GAMEPAD_BUTTON_BACK},   // Minus
    // L/R
    {0.02, 0.45, 0.12, 0.52, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER},
    {0.88, 0.45, 0.98, 0.52, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER},
};
#define TOUCH_MAP_COUNT (sizeof(touch_map) / sizeof(touch_map[0]))

// Estado de dedos activos: finger_id -> botón presionado
#define MAX_FINGERS 10
static struct {
    SDL_FingerID finger;
    int button;
    bool active;
} fingers[MAX_FINGERS];

void ios_touch_init(void) {
    SDL_VirtualJoystickDesc desc;
    SDL_zero(desc);
    desc.version = SDL_VIRTUAL_JOYSTICK_DESC_VERSION;
    desc.type = SDL_JOYSTICK_TYPE_GAMEPAD;
    desc.naxes = 2;  // left stick X/Y
    desc.nbuttons = SDL_GAMEPAD_BUTTON_COUNT;
    desc.name = "iOS Touch Controls";

    vjoy_id = SDL_AttachVirtualJoystick(&desc);
    if (vjoy_id != 0) {
        vjoy = SDL_OpenJoystick(vjoy_id);
    }

    for (int i = 0; i < MAX_FINGERS; i++) {
        fingers[i].active = false;
    }
}

void ios_touch_quit(void) {
    if (vjoy) {
        SDL_CloseJoystick(vjoy);
        vjoy = NULL;
    }
    if (vjoy_id != 0) {
        SDL_DetachVirtualJoystick(vjoy_id);
        vjoy_id = 0;
    }
}

static int find_button(float x, float y) {
    for (unsigned i = 0; i < TOUCH_MAP_COUNT; i++) {
        if (x >= touch_map[i].x0 && x <= touch_map[i].x1 &&
            y >= touch_map[i].y0 && y <= touch_map[i].y1) {
            return touch_map[i].button;
        }
    }
    return -1;
}

static int find_finger(SDL_FingerID id) {
    for (int i = 0; i < MAX_FINGERS; i++) {
        if (fingers[i].active && fingers[i].finger == id) return i;
    }
    return -1;
}

static int alloc_finger(SDL_FingerID id) {
    for (int i = 0; i < MAX_FINGERS; i++) {
        if (!fingers[i].active) {
            fingers[i].active = true;
            fingers[i].finger = id;
            fingers[i].button = -1;
            return i;
        }
    }
    return -1;
}

// Llamar desde el loop de eventos SDL. Retorna true si el evento fue consumido.
bool ios_touch_handle_event(const SDL_Event *e) {
    if (!vjoy) return false;

    switch (e->type) {
    case SDL_EVENT_FINGER_DOWN: {
        float x = e->tfinger.x;
        float y = e->tfinger.y;
        int btn = find_button(x, y);
        int idx = alloc_finger(e->tfinger.fingerID);
        if (idx >= 0) {
            fingers[idx].button = btn;
            if (btn >= 0) {
                SDL_SetJoystickVirtualButton(vjoy, btn, true);
            }
        }
        return true;
    }
    case SDL_EVENT_FINGER_UP:
    case SDL_EVENT_FINGER_CANCELED: {
        int idx = find_finger(e->tfinger.fingerID);
        if (idx >= 0) {
            if (fingers[idx].button >= 0) {
                SDL_SetJoystickVirtualButton(vjoy, fingers[idx].button, false);
            }
            fingers[idx].active = false;
        }
        return true;
    }
    case SDL_EVENT_FINGER_MOTION: {
        // Para el D-pad analógico futuro; por ahora solo botones
        int idx = find_finger(e->tfinger.fingerID);
        if (idx >= 0) {
            float x = e->tfinger.x;
            float y = e->tfinger.y;
            int new_btn = find_button(x, y);
            int old_btn = fingers[idx].button;
            if (new_btn != old_btn) {
                if (old_btn >= 0) SDL_SetJoystickVirtualButton(vjoy, old_btn, false);
                if (new_btn >= 0) SDL_SetJoystickVirtualButton(vjoy, new_btn, true);
                fingers[idx].button = new_btn;
            }
        }
        return true;
    }
    }
    return false;
}
