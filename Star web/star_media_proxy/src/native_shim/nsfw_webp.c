// SPDX-License-Identifier: AGPL-3.0-or-later

#include "native_shim_internal.h"

static int star_emit_rgba_nsfw_frame(
    const uint8_t *rgba,
    int width,
    int height,
    long long deadline_monotonic_ms,
    size_t max_frame_output_size,
    struct star_nsfw_frame_out *out
) {
    size_t rgba_size = 0;
    if (rgba == NULL || out == NULL || deadline_monotonic_ms < 0 ||
        max_frame_output_size == 0) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    int deadline_status = star_native_deadline_status(
        deadline_monotonic_ms);
    if (deadline_status != STAR_NATIVE_STATUS_OK) return deadline_status;
    if (ff_validate_rgba_geometry(width, height, &rgba_size) != 0) {
        return STAR_NATIVE_STATUS_INVALID_DIMENSIONS;
    }
    VipsImage *image = vips_image_new_from_memory(
        rgba, rgba_size, width, height, 4, VIPS_FORMAT_UCHAR);
    if (image == NULL) return STAR_NATIVE_STATUS_ALLOCATION_FAILED;
    int rc = ff_fit_frame_image(
        &image, STAR_NSFW_FRAME_MAX_DIMENSION, STAR_NSFW_FRAME_MAX_DIMENSION);
    deadline_status = star_native_deadline_status(deadline_monotonic_ms);
    if (deadline_status != STAR_NATIVE_STATUS_OK) rc = deadline_status;
    void *out_buf = NULL;
    size_t out_size = 0;
    size_t out_capacity = 0;
    if (rc == STAR_NATIVE_STATUS_OK) {
        rc = star_vips_image_write_to_buffer_bounded(
            image, ".jpg[Q=65,strip]", deadline_monotonic_ms,
            max_frame_output_size,
            &out_buf, &out_size, &out_capacity);
    }
    g_object_unref(image);
    if (rc == STAR_NATIVE_STATUS_OK && out_buf != NULL && out_size > 0 &&
        out_capacity >= out_size && out_capacity <= max_frame_output_size) {
        out->data = out_buf;
        out->len = out_size;
        return STAR_NATIVE_STATUS_OK;
    }
    if (out_buf != NULL) g_free(out_buf);
    if (rc != STAR_NATIVE_STATUS_OK) return rc;
    return STAR_NATIVE_STATUS_CODEC_FAILURE;
}

struct star_webp_nsfw_request {
    const void *data;
    size_t len;
    int thread_level;
    const int *indices;
    size_t count;
    long long deadline_monotonic_ms;
    int max_frames;
    size_t max_total_pixels;
    size_t max_frame_output_size;
    struct star_nsfw_frame_out *outputs;
};

struct star_webp_nsfw_selection {
    WebPAnimDecoder *decoder;
    WebPAnimInfo info;
    const int *indices;
    size_t count;
    size_t next;
    long long deadline_monotonic_ms;
    size_t max_frame_output_size;
    struct star_nsfw_frame_out *outputs;
};

static int star_webp_nsfw_request_valid(
    const struct star_webp_nsfw_request *request
) {
    assert(request != NULL);
    if (request->data == NULL) return 0;
    if (request->len == 0) return 0;
    if (request->indices == NULL) return 0;
    if (request->outputs == NULL) return 0;
    if (request->count == 0) return 0;
    if (request->count > STAR_MAX_NSFW_SAMPLES) return 0;
    if (request->deadline_monotonic_ms < 0) return 0;
    if (request->max_frames <= 0) return 0;
    if (request->max_total_pixels == 0) return 0;
    if (request->max_frame_output_size == 0) return 0;
    if (request->thread_level < 0) return 0;
    if (request->thread_level > 1) return 0;
    return 1;
}

static int star_webp_nsfw_info_valid(
    const WebPAnimInfo *info,
    const struct star_webp_animation_facts *facts,
    const struct star_webp_nsfw_request *request
) {
    assert(info != NULL);
    assert(facts != NULL);
    assert(request != NULL);
    if (info->canvas_width != facts->canvas_width) return 0;
    if (info->canvas_height != facts->canvas_height) return 0;
    if (info->frame_count != facts->frame_count) return 0;
    return star_nsfw_animation_selection_valid(
        request->indices, request->count, (int)info->frame_count);
}

static int star_webp_open_nsfw_decoder(
    const struct star_webp_nsfw_request *request,
    WebPAnimDecoder **out_decoder,
    WebPAnimInfo *out_info
) {
    assert(request != NULL);
    assert(out_decoder != NULL);
    assert(out_info != NULL);
    *out_decoder = NULL;
    int status = star_native_deadline_status(
        request->deadline_monotonic_ms);
    if (status != STAR_NATIVE_STATUS_OK) return status;
    struct star_webp_animation_facts facts;
    status = star_webp_animation_preflight(
        request->data, request->len, request->max_frames,
        request->max_total_pixels, request->deadline_monotonic_ms, &facts);
    int deadline_status = star_native_deadline_status(
        request->deadline_monotonic_ms);
    if (deadline_status != STAR_NATIVE_STATUS_OK) return deadline_status;
    if (status != STAR_NATIVE_STATUS_OK) return status;
    if (ff_validate_rgba_geometry(
            (int)facts.canvas_width, (int)facts.canvas_height, NULL) != 0) {
        return STAR_NATIVE_STATUS_INVALID_DIMENSIONS;
    }
    WebPData input = { .bytes = request->data, .size = request->len };
    WebPAnimDecoderOptions options;
    if (!WebPAnimDecoderOptionsInit(&options)) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    options.color_mode = MODE_RGBA;
    options.use_threads = request->thread_level;
    status = star_native_deadline_status(request->deadline_monotonic_ms);
    if (status != STAR_NATIVE_STATUS_OK) return status;
    WebPAnimDecoder *decoder = WebPAnimDecoderNew(&input, &options);
    status = star_native_deadline_status(request->deadline_monotonic_ms);
    if (status != STAR_NATIVE_STATUS_OK) {
        if (decoder != NULL) WebPAnimDecoderDelete(decoder);
        return status;
    }
    if (decoder == NULL) return STAR_NATIVE_STATUS_CODEC_FAILURE;
    int info_valid = WebPAnimDecoderGetInfo(decoder, out_info) &&
        star_webp_nsfw_info_valid(out_info, &facts, request);
    status = star_native_deadline_status(request->deadline_monotonic_ms);
    if (status != STAR_NATIVE_STATUS_OK) {
        WebPAnimDecoderDelete(decoder);
        return status;
    }
    if (!info_valid) {
        WebPAnimDecoderDelete(decoder);
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    *out_decoder = decoder;
    return STAR_NATIVE_STATUS_OK;
}

static int star_webp_decode_nsfw_selection(
    struct star_webp_nsfw_selection *selection
) {
    assert(selection != NULL);
    assert(selection->decoder != NULL);
    assert(selection->indices != NULL);
    assert(selection->outputs != NULL);
    assert(selection->count > 0);
    for (int frame = 0; frame < (int)selection->info.frame_count; frame++) {
        int deadline_status = star_native_deadline_status(
            selection->deadline_monotonic_ms);
        if (deadline_status != STAR_NATIVE_STATUS_OK) {
            return deadline_status;
        }
        uint8_t *rgba = NULL;
        int timestamp = 0;
        if (!WebPAnimDecoderGetNext(
                selection->decoder, &rgba, &timestamp)) {
            deadline_status = star_native_deadline_status(
                selection->deadline_monotonic_ms);
            if (deadline_status != STAR_NATIVE_STATUS_OK) {
                return deadline_status;
            }
            return STAR_NATIVE_STATUS_CODEC_FAILURE;
        }
        deadline_status = star_native_deadline_status(
            selection->deadline_monotonic_ms);
        if (deadline_status != STAR_NATIVE_STATUS_OK) {
            return deadline_status;
        }
        if (selection->next >= selection->count) continue;
        if (frame != selection->indices[selection->next]) continue;
        int status = star_emit_rgba_nsfw_frame(
            rgba,
            (int)selection->info.canvas_width,
            (int)selection->info.canvas_height,
            selection->deadline_monotonic_ms,
            selection->max_frame_output_size,
            &selection->outputs[selection->next]);
        if (status != STAR_NATIVE_STATUS_OK) return status;
        selection->next++;
    }
    if (selection->next != selection->count) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    int has_more = WebPAnimDecoderHasMoreFrames(selection->decoder);
    int deadline_status = star_native_deadline_status(
        selection->deadline_monotonic_ms);
    if (deadline_status != STAR_NATIVE_STATUS_OK) return deadline_status;
    if (has_more) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    return STAR_NATIVE_STATUS_OK;
}

int star_webp_extract_frames_for_nsfw(
    const void *webp_data,
    size_t webp_len,
    int thread_level,
    long long deadline_monotonic_ms,
    const int *frame_indices,
    size_t n_indices,
    int max_frames,
    size_t max_total_pixels,
    size_t max_frame_output_size,
    struct star_nsfw_frame_out *out_frames
) {
    if (n_indices > STAR_MAX_NSFW_SAMPLES) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }
    star_nsfw_frames_reset(out_frames, n_indices);
    struct star_webp_nsfw_request request = {
        .data = webp_data,
        .len = webp_len,
        .thread_level = thread_level,
        .indices = frame_indices,
        .count = n_indices,
        .deadline_monotonic_ms = deadline_monotonic_ms,
        .max_frames = max_frames,
        .max_total_pixels = max_total_pixels,
        .max_frame_output_size = max_frame_output_size,
        .outputs = out_frames,
    };
    if (!star_webp_nsfw_request_valid(&request)) {
        return STAR_NATIVE_STATUS_CODEC_FAILURE;
    }

    WebPAnimInfo info = {0};
    WebPAnimDecoder *decoder = NULL;
    int status = star_webp_open_nsfw_decoder(
        &request, &decoder, &info);
    if (status != STAR_NATIVE_STATUS_OK) return status;
    struct star_webp_nsfw_selection selection = {
        .decoder = decoder,
        .info = info,
        .indices = request.indices,
        .count = request.count,
        .deadline_monotonic_ms = request.deadline_monotonic_ms,
        .max_frame_output_size = request.max_frame_output_size,
        .outputs = request.outputs,
    };
    status = star_webp_decode_nsfw_selection(&selection);
    WebPAnimDecoderDelete(decoder);
    if (status != STAR_NATIVE_STATUS_OK) {
        star_nsfw_frames_free(out_frames, n_indices);
    }
    return status;
}
