// Copyright (c) 2022 XMOS LIMITED. This Software is subject to the terms of the
// XMOS Public License: Version 1

#ifndef INFERENCE_ENGINE_H_
#define INFERENCE_ENGINE_H_

#include <stdint.h>

/* Generic interface for inference engines */
int32_t inference_engine_create(uint32_t priority, void *args);
int32_t inference_engine_sample_push(int32_t *buf, size_t frames);

void inference_engine_full_power_request(void);
void inference_engine_low_power_accept(void);
uint8_t inference_engine_low_power_ready(void);
void inference_engine_low_power_reset(void);
int32_t inference_engine_keyword_queue_count(void);
void inference_engine_keyword_queue_complete(void);

#endif /* INFERENCE_ENGINE_H_ */
