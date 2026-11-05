#!/bin/bash

cache_dir="$HOME/.config/hypr/.cache"
mkdir -p "$cache_dir"
shader_dir="$HOME/.config/hypr/shaders"
mkdir -p "$shader_dir"
shader_file="$shader_dir/nightlight.glsl"

temp_file="$cache_dir/.nightlight"
state_file="$cache_dir/.nightlight_status"

default_temp=3500
min_temp=2000
max_temp=6000
step=400

generate_shader() {
    local temp="$1"
    cat << EOF > "$shader_file"
/*
 * Blue Light Filter for Hyprland (GPU Shader)
 * Optimized for hardware-agnostic night light (including NVIDIA GT 710 / nouveau)
 */

#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float Temperature = ${temp}.0;
const float Strength = 1.0;

#define WithQuickAndDirtyLuminancePreservation
const float LuminancePreservationFactor = 1.0;

vec3 colorTemperatureToRGB(const in float temperature) {
    mat3 m = (temperature <= 6500.0)
        ? mat3(vec3(0.0, -2902.1955373783176, -8257.7997278925690),
               vec3(0.0, 1669.5803561666639, 2575.2827530017594),
               vec3(1.0, 1.3302673723350029, 1.8993753891711275))
        : mat3(vec3(1745.0425298314172, 1216.6168361476490, -8257.7997278925690),
               vec3(-2666.3474220535695, -2173.1012343082230, 2575.2827530017594),
               vec3(0.55995389139931482, 0.70381203140554553, 1.8993753891711275));

    return mix(
        clamp(m[0] / (vec3(clamp(temperature, 1000.0, 40000.0)) + m[1]) + m[2], 0.0, 1.0),
        vec3(1.0),
        smoothstep(1000.0, 0.0, temperature)
    );
}

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;

#ifdef WithQuickAndDirtyLuminancePreservation
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color *= mix(1.0, lum / max(lum, 1e-5), LuminancePreservationFactor);
#endif

    color = mix(color, color * colorTemperatureToRGB(Temperature), Strength);

    fragColor = vec4(color, pixColor.a);
}
EOF
}

get_temp() {
    local val
    val=$(cat "$temp_file" 2>/dev/null)
    if [[ ! "$val" =~ ^[0-9]+$ ]] || [ "$val" -lt "$min_temp" ] || [ "$val" -gt "$max_temp" ]; then
        val="$default_temp"
    fi
    echo "$val"
}

is_active() {
    local st
    st=$(cat "$state_file" 2>/dev/null)
    [ "$st" = "on" ]
}

apply_warm() {
    local temp="$1"
    generate_shader "$temp"
    
    # 1. Apply OpenGL Screen Shader via Hyprland Lua API (works on GT 710 and nouveau!)
    hyprctl eval "hl.config({ decoration = { screen_shader = '[[EMPTY]]' } }); hl.config({ decoration = { screen_shader = '${shader_file}' } })" >/dev/null 2>&1
    
    # 2. Also update hyprsunset (if running)
    hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1
    
    echo "$temp" > "$temp_file"
    echo "on" > "$state_file"
    notify-send -u low -i preferences-desktop-display-color "Night Light" "Eye Comfort Active: ${temp}K (Warm)"
    pkill -RTMIN+11 waybar 2>/dev/null
}

apply_daylight() {
    # 1. Disable OpenGL Screen Shader via Hyprland Lua API
    hyprctl eval "hl.config({ decoration = { screen_shader = '[[EMPTY]]' } })" >/dev/null 2>&1
    
    # 2. Reset hyprsunset
    hyprctl hyprsunset identity >/dev/null 2>&1
    
    echo "off" > "$state_file"
    notify-send -u low -i preferences-desktop-display-color "Night Light" "Screen reset to Daylight (Off)"
    pkill -RTMIN+11 waybar 2>/dev/null
}

case "$1" in
    --status|"")
        current=$(get_temp)
        if is_active; then
            echo "{\"text\": \"󰖔\", \"alt\": \"active\", \"tooltip\": \"Night Light: Active (${current}K)\nLeft Click: Turn Off\nScroll Up: Warmer (More Amber)\nScroll Down: Cooler\nRight Click: Reset to Daylight\", \"class\": \"active\"}"
        else
            echo "{\"text\": \"󰖙\", \"alt\": \"inactive\", \"tooltip\": \"Night Light: Off (Normal Daylight)\nLeft Click: Turn On (Eye Comfort)\nScroll Up: Warmer\nRight Click: Reset\", \"class\": \"inactive\"}"
        fi
        ;;
    --toggle|--value)
        if is_active; then
            apply_daylight
        else
            current=$(get_temp)
            apply_warm "$current"
        fi
        ;;
    --inc)
        # Cooler (higher Kelvin towards 6000K, or switch to daylight)
        current=$(get_temp)
        new_temp=$((current + step))
        if [ "$new_temp" -gt "$max_temp" ]; then
            apply_daylight
        else
            apply_warm "$new_temp"
        fi
        ;;
    --dec)
        # Warmer (lower Kelvin towards 2000K)
        current=$(get_temp)
        if ! is_active; then
            apply_warm "$current"
        else
            new_temp=$((current - step))
            [ "$new_temp" -lt "$min_temp" ] && new_temp="$min_temp"
            apply_warm "$new_temp"
        fi
        ;;
    --def)
        echo "$default_temp" > "$temp_file"
        apply_daylight
        ;;
    --init)
        if is_active; then
            current=$(get_temp)
            apply_warm "$current"
        else
            apply_daylight
        fi
        ;;
    *)
        echo "Usage: $0 {--status|--toggle|--inc|--dec|--def|--init}"
        ;;
esac
