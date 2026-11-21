// SPDX-License-Identifier: AGPL-3.0-or-later

#pragma once

#include <stddef.h>
#include <stdint.h>
#include <webp/encode.h>

struct star_webp_animation_facts {
    uint32_t canvas_width;
    uint32_t canvas_height;
    uint32_t frame_count;
};

int star_webp_animation_preflight(
    const void *webp_data,
    size_t webp_len,
    int max_frames,
    size_t max_total_pixels,
    long long deadline_monotonic_ms,
    struct star_webp_animation_facts *facts
);

int star_configure_webp_encoder(
    WebPConfig *config,
    int quality,
    int lossless,
    int effort,
    int alpha_q,
    int smart_subsample
);

enum star_webp_pixel_layout {
    STAR_WEBP_PIXEL_LAYOUT_RGBA = 0,
    STAR_WEBP_PIXEL_LAYOUT_BGRA = 1
};

struct star_webp_animation_encoder;

struct star_webp_animation_encoder_settings {
    const WebPConfig *config;
    int canvas_width;
    int canvas_height;
    int loop_count;
    int full_canvas_frames;
    enum star_webp_pixel_layout pixel_layout;
    long long deadline_monotonic_ms;
    size_t max_output_size;
};

int star_webp_animation_encoder_create(
    const struct star_webp_animation_encoder_settings *settings,
    struct star_webp_animation_encoder **out_encoder
);

int star_webp_animation_encoder_add(
    struct star_webp_animation_encoder *encoder,
    const uint8_t *pixels,
    size_t stride,
    int duration_ms
);

int star_webp_animation_encoder_finish(
    struct star_webp_animation_encoder *encoder,
    void **out_buf,
    size_t *out_size
);

void star_webp_animation_encoder_delete(
    struct star_webp_animation_encoder *encoder
);
