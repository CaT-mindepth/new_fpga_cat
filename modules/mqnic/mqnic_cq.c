/*

Copyright 2019, The Regents of the University of California.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA ''AS
IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OF THE UNIVERSITY OF CALIFORNIA OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of The Regents of the University of California.

*/

#include "mqnic.h"

int mqnic_create_cq_ring(struct mqnic_priv *priv, struct mqnic_cq_ring **ring_ptr, int size, int stride, int index, u8 __iomem *hw_addr)
{
    struct device *dev = priv->dev;
    struct mqnic_cq_ring *ring;
    int ret;

    ring = kzalloc(sizeof(*ring), GFP_KERNEL);
    if (!ring)
    {
        dev_err(dev, "Failed to allocate CQ ring");
        return -ENOMEM;
    }

    ring->ndev = priv->ndev;

    ring->size = roundup_pow_of_two(size);
    ring->size_mask = ring->size-1;
    ring->stride = roundup_pow_of_two(stride);

    ring->buf_size = ring->size*ring->stride;
    ring->buf = dma_alloc_coherent(dev, ring->buf_size, &ring->buf_dma_addr, GFP_KERNEL);
    if (!ring->buf)
    {
        dev_err(dev, "Failed to allocate CQ ring DMA buffer");
        ret = -ENOMEM;
        goto fail_ring;
    }

    ring->hw_addr = hw_addr;
    ring->hw_ptr_mask = 0xffff;
    ring->hw_head_ptr = hw_addr+MQNIC_CPL_QUEUE_HEAD_PTR_REG;
    ring->hw_tail_ptr = hw_addr+MQNIC_CPL_QUEUE_TAIL_PTR_REG;

    ring->head_ptr = 0;
    ring->tail_ptr = 0;

    // deactivate queue
    iowrite32(0, ring->hw_addr+MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG);
    // set base address
    iowrite32(ring->buf_dma_addr, ring->hw_addr+MQNIC_CPL_QUEUE_BASE_ADDR_REG+0);
    iowrite32(ring->buf_dma_addr >> 32, ring->hw_addr+MQNIC_CPL_QUEUE_BASE_ADDR_REG+4);
    // set interrupt index
    iowrite32(0, ring->hw_addr+MQNIC_CPL_QUEUE_INTERRUPT_INDEX_REG);
    // set pointers
    iowrite32(ring->head_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_CPL_QUEUE_HEAD_PTR_REG);
    iowrite32(ring->tail_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_CPL_QUEUE_TAIL_PTR_REG);
    // set size
    iowrite32(ilog2(ring->size), ring->hw_addr+MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG);

    *ring_ptr = ring;
    return 0;

fail_ring:
    kfree(ring);
    *ring_ptr = NULL;
    return ret;
}

void mqnic_destroy_cq_ring(struct mqnic_priv *priv, struct mqnic_cq_ring **ring_ptr)
{
    struct device *dev = priv->dev;
    struct mqnic_cq_ring *ring = *ring_ptr;
    *ring_ptr = NULL;

    mqnic_deactivate_cq_ring(priv, ring);

    dma_free_coherent(dev, ring->buf_size, ring->buf, ring->buf_dma_addr);
    kfree(ring);
}

int mqnic_activate_cq_ring(struct mqnic_priv *priv, struct mqnic_cq_ring *ring, int eq_index)
{
    ring->eq_index = eq_index;

    // deactivate queue
    iowrite32(0, ring->hw_addr+MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG);
    // set base address
    iowrite32(ring->buf_dma_addr, ring->hw_addr+MQNIC_CPL_QUEUE_BASE_ADDR_REG+0);
    iowrite32(ring->buf_dma_addr >> 32, ring->hw_addr+MQNIC_CPL_QUEUE_BASE_ADDR_REG+4);
    // set interrupt index
    iowrite32(eq_index, ring->hw_addr+MQNIC_CPL_QUEUE_INTERRUPT_INDEX_REG);
    // set pointers
    iowrite32(ring->head_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_CPL_QUEUE_HEAD_PTR_REG);
    iowrite32(ring->tail_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_CPL_QUEUE_TAIL_PTR_REG);
    // set size and activate queue
    iowrite32(ilog2(ring->size) | MQNIC_CPL_QUEUE_ACTIVE_MASK, ring->hw_addr+MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG);

    return 0;
}

void mqnic_deactivate_cq_ring(struct mqnic_priv *priv, struct mqnic_cq_ring *ring)
{
    // deactivate queue
    iowrite32(ilog2(ring->size), ring->hw_addr+MQNIC_CPL_QUEUE_ACTIVE_LOG_SIZE_REG);
    // disarm queue
    iowrite32(ring->eq_index, ring->hw_addr+MQNIC_CPL_QUEUE_INTERRUPT_INDEX_REG);
}

bool mqnic_is_cq_ring_empty(const struct mqnic_cq_ring *ring)
{
    return ring->head_ptr == ring->tail_ptr;
}

bool mqnic_is_cq_ring_full(const struct mqnic_cq_ring *ring)
{
    return ring->head_ptr - ring->tail_ptr >= ring->size;
}

void mqnic_cq_read_head_ptr(struct mqnic_cq_ring *ring)
{
    ring->head_ptr += (ioread32(ring->hw_head_ptr) - ring->head_ptr) & ring->hw_ptr_mask;
}

void mqnic_cq_write_tail_ptr(struct mqnic_cq_ring *ring)
{
    iowrite32(ring->tail_ptr & ring->hw_ptr_mask, ring->hw_tail_ptr);
}

void mqnic_arm_cq(struct mqnic_cq_ring *ring)
{
    iowrite32(ring->eq_index | MQNIC_CPL_QUEUE_ARM_MASK, ring->hw_addr+MQNIC_CPL_QUEUE_INTERRUPT_INDEX_REG);
}

