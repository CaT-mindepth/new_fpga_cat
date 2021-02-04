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

#include <linux/version.h>
#include "mqnic.h"

int mqnic_create_tx_ring(struct mqnic_priv *priv, struct mqnic_ring **ring_ptr, int size, int stride, int index, u8 __iomem *hw_addr)
{
    struct device *dev = priv->dev;
    struct mqnic_ring *ring;
    int ret;

    ring = kzalloc(sizeof(*ring), GFP_KERNEL);
    if (!ring)
    {
        dev_err(dev, "Failed to allocate TX ring");
        return -ENOMEM;
    }

    ring->size = roundup_pow_of_two(size);
    ring->full_size = ring->size >> 1;
    ring->size_mask = ring->size-1;
    ring->stride = roundup_pow_of_two(stride);

    ring->desc_block_size = ring->stride/MQNIC_DESC_SIZE;
    ring->log_desc_block_size = ring->desc_block_size < 2 ? 0 : ilog2(ring->desc_block_size-1)+1;
    ring->desc_block_size = 1 << ring->log_desc_block_size;

    ring->tx_info = kvzalloc(sizeof(*ring->tx_info)*ring->size, GFP_KERNEL);
    if (!ring->tx_info)
    {
        dev_err(dev, "Failed to allocate tx_info");
        ret = -ENOMEM;
        goto fail_ring;
    }

    ring->buf_size = ring->size*ring->stride;
    ring->buf = dma_alloc_coherent(dev, ring->buf_size, &ring->buf_dma_addr, GFP_KERNEL);
    if (!ring->buf)
    {
        dev_err(dev, "Failed to allocate TX ring DMA buffer");
        ret = -ENOMEM;
        goto fail_info;
    }

    ring->hw_addr = hw_addr;
    ring->hw_ptr_mask = 0xffff;
    ring->hw_head_ptr = hw_addr+MQNIC_QUEUE_HEAD_PTR_REG;
    ring->hw_tail_ptr = hw_addr+MQNIC_QUEUE_TAIL_PTR_REG;

    ring->head_ptr = 0;
    ring->tail_ptr = 0;
    ring->clean_tail_ptr = 0;

    // deactivate queue
    iowrite32(0, ring->hw_addr+MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG);
    // set base address
    iowrite32(ring->buf_dma_addr, ring->hw_addr+MQNIC_QUEUE_BASE_ADDR_REG+0);
    iowrite32(ring->buf_dma_addr >> 32, ring->hw_addr+MQNIC_QUEUE_BASE_ADDR_REG+4);
    // set completion queue index
    iowrite32(0, ring->hw_addr+MQNIC_QUEUE_CPL_QUEUE_INDEX_REG);
    // set pointers
    iowrite32(ring->head_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_QUEUE_HEAD_PTR_REG);
    iowrite32(ring->tail_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_QUEUE_TAIL_PTR_REG);
    // set size
    iowrite32(ilog2(ring->size) | (ring->log_desc_block_size << 8), ring->hw_addr+MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG);

    *ring_ptr = ring;
    return 0;

fail_info:
    kvfree(ring->tx_info);
    ring->tx_info = NULL;
fail_ring:
    kfree(ring);
    *ring_ptr = NULL;
    return ret;
}

void mqnic_destroy_tx_ring(struct mqnic_priv *priv, struct mqnic_ring **ring_ptr)
{
    struct device *dev = priv->dev;
    struct mqnic_ring *ring = *ring_ptr;
    *ring_ptr = NULL;

    mqnic_deactivate_tx_ring(priv, ring);

    mqnic_free_tx_buf(priv, ring);

    dma_free_coherent(dev, ring->buf_size, ring->buf, ring->buf_dma_addr);
    kvfree(ring->tx_info);
    ring->tx_info = NULL;
    kfree(ring);
}

int mqnic_activate_tx_ring(struct mqnic_priv *priv, struct mqnic_ring *ring, int cpl_index)
{
    // deactivate queue
    iowrite32(0, ring->hw_addr+MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG);
    // set base address
    iowrite32(ring->buf_dma_addr, ring->hw_addr+MQNIC_QUEUE_BASE_ADDR_REG+0);
    iowrite32(ring->buf_dma_addr >> 32, ring->hw_addr+MQNIC_QUEUE_BASE_ADDR_REG+4);
    // set completion queue index
    iowrite32(cpl_index, ring->hw_addr+MQNIC_QUEUE_CPL_QUEUE_INDEX_REG);
    // set pointers
    iowrite32(ring->head_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_QUEUE_HEAD_PTR_REG);
    iowrite32(ring->tail_ptr & ring->hw_ptr_mask, ring->hw_addr+MQNIC_QUEUE_TAIL_PTR_REG);
    // set size and activate queue
    iowrite32(ilog2(ring->size) | (ring->log_desc_block_size << 8) | MQNIC_QUEUE_ACTIVE_MASK, ring->hw_addr+MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG);

    return 0;
}

void mqnic_deactivate_tx_ring(struct mqnic_priv *priv, struct mqnic_ring *ring)
{
    // deactivate queue
    iowrite32(ilog2(ring->size) | (ring->log_desc_block_size << 8), ring->hw_addr+MQNIC_QUEUE_ACTIVE_LOG_SIZE_REG);
}

bool mqnic_is_tx_ring_empty(const struct mqnic_ring *ring)
{
    return ring->head_ptr == ring->clean_tail_ptr;
}

bool mqnic_is_tx_ring_full(const struct mqnic_ring *ring)
{
    return ring->head_ptr - ring->clean_tail_ptr >= ring->full_size;
}

void mqnic_tx_read_tail_ptr(struct mqnic_ring *ring)
{
    ring->tail_ptr += (ioread32(ring->hw_tail_ptr) - ring->tail_ptr) & ring->hw_ptr_mask;
}

void mqnic_tx_write_head_ptr(struct mqnic_ring *ring)
{
    iowrite32(ring->head_ptr & ring->hw_ptr_mask, ring->hw_head_ptr);
}

void mqnic_free_tx_desc(struct mqnic_priv *priv, struct mqnic_ring *ring, int index, int napi_budget)
{
    struct mqnic_tx_info *tx_info = &ring->tx_info[index];
    struct sk_buff *skb = tx_info->skb;
    u32 i;

    prefetchw(&skb->users);

    dma_unmap_single(priv->dev, dma_unmap_addr(tx_info, dma_addr), dma_unmap_len(tx_info, len), PCI_DMA_TODEVICE);
    dma_unmap_addr_set(tx_info, dma_addr, 0);

    // unmap frags
    for (i = 0; i < tx_info->frag_count; i++)
    {
        dma_unmap_page(priv->dev, tx_info->frags[i].dma_addr, tx_info->frags[i].len, PCI_DMA_TODEVICE);
    }

    napi_consume_skb(skb, napi_budget);
    tx_info->skb = NULL;
}

int mqnic_free_tx_buf(struct mqnic_priv *priv, struct mqnic_ring *ring)
{
    u32 index;
    int cnt = 0;

    while (!mqnic_is_tx_ring_empty(ring))
    {
        index = ring->clean_tail_ptr & ring->size_mask;
        mqnic_free_tx_desc(priv, ring, index, 0);
        ring->clean_tail_ptr++;
        cnt++;
    }

    ring->head_ptr = 0;
    ring->tail_ptr = 0;
    ring->clean_tail_ptr = 0;

    return cnt;
}

int mqnic_process_tx_cq(struct net_device *ndev, struct mqnic_cq_ring *cq_ring, int napi_budget)
{
    struct mqnic_priv *priv = netdev_priv(ndev);
    struct mqnic_ring *ring = priv->tx_ring[cq_ring->ring_index];
    struct mqnic_tx_info *tx_info;
    struct mqnic_cpl *cpl;
    u32 cq_index;
    u32 cq_tail_ptr;
    u32 ring_index;
    u32 ring_clean_tail_ptr;
    u32 packets = 0;
    u32 bytes = 0;
    int done = 0;
    int budget = napi_budget;

    if (unlikely(!priv->port_up))
    {
        return done;
    }

    // prefetch for BQL
    netdev_txq_bql_complete_prefetchw(ring->tx_queue);

    // process completion queue
    // read head pointer from NIC
    mqnic_cq_read_head_ptr(cq_ring);

    cq_tail_ptr = cq_ring->tail_ptr;
    cq_index = cq_tail_ptr & cq_ring->size_mask;

    while (cq_ring->head_ptr != cq_tail_ptr && done < budget)
    {
        cpl = (struct mqnic_cpl *)(cq_ring->buf + cq_index*cq_ring->stride);
        ring_index = cpl->index & ring->size_mask;
        tx_info = &ring->tx_info[ring_index];

        // TX hardware timestamp
        if (unlikely(tx_info->ts_requested))
        {
            struct skb_shared_hwtstamps hwts;
            dev_info(priv->dev, "mqnic_process_tx_cq TX TS requested");
            hwts.hwtstamp = mqnic_read_cpl_ts(priv->mdev, ring, cpl);
            skb_tstamp_tx(tx_info->skb, &hwts);
        }

        // free TX descriptor
        mqnic_free_tx_desc(priv, ring, ring_index, napi_budget);

        packets++;
        bytes += cpl->len;

        done++;

        cq_tail_ptr++;
        cq_index = cq_tail_ptr & cq_ring->size_mask;
    }

    // update CQ tail
    cq_ring->tail_ptr = cq_tail_ptr;
    mqnic_cq_write_tail_ptr(cq_ring);

    // process ring
    // read tail pointer from NIC
    mqnic_tx_read_tail_ptr(ring);

    ring_clean_tail_ptr = READ_ONCE(ring->clean_tail_ptr);
    ring_index = ring_clean_tail_ptr & ring->size_mask;

    while (ring_clean_tail_ptr != ring->tail_ptr)
    {
        tx_info = &ring->tx_info[ring_index];

        if (tx_info->skb)
            break;

        ring_clean_tail_ptr++;
        ring_index = ring_clean_tail_ptr & ring->size_mask;
    }

    // update ring tail
    WRITE_ONCE(ring->clean_tail_ptr, ring_clean_tail_ptr);

    // BQL
    //netdev_tx_completed_queue(ring->tx_queue, packets, bytes);

    // wake queue if it is stopped
    if (netif_tx_queue_stopped(ring->tx_queue) && !mqnic_is_tx_ring_full(ring))
    {
        netif_tx_wake_queue(ring->tx_queue);
    }

    return done;
}

void mqnic_tx_irq(struct mqnic_cq_ring *cq)
{
    struct mqnic_priv *priv = netdev_priv(cq->ndev);

    if (likely(priv->port_up))
    {
        napi_schedule_irqoff(&cq->napi);
    }
    else
    {
        mqnic_arm_cq(cq);
    }
}

int mqnic_poll_tx_cq(struct napi_struct *napi, int budget)
{
    struct mqnic_cq_ring *cq_ring = container_of(napi, struct mqnic_cq_ring, napi);
    struct net_device *ndev = cq_ring->ndev;
    int done;

    done = mqnic_process_tx_cq(ndev, cq_ring, budget);

    if (done == budget)
    {
        return done;
    }

    napi_complete(napi);

    mqnic_arm_cq(cq_ring);

    return done;
}

static bool mqnic_map_skb(struct mqnic_priv *priv, struct mqnic_ring *ring, struct mqnic_tx_info *tx_info, struct mqnic_desc *tx_desc, struct sk_buff *skb)
{
    struct skb_shared_info *shinfo = skb_shinfo(skb);
    u32 i;
    u32 len;
    dma_addr_t dma_addr;

    // update tx_info
    tx_info->skb = skb;
    tx_info->frag_count = 0;

    for (i = 0; i < shinfo->nr_frags; i++)
    {
        const skb_frag_t *frag = &shinfo->frags[i];
        len = skb_frag_size(frag);
        dma_addr = skb_frag_dma_map(priv->dev, frag, 0, len, DMA_TO_DEVICE);
        if (unlikely(dma_mapping_error(priv->dev, dma_addr)))
        {
            // mapping failed
            goto map_error;
        }

        // write descriptor
        tx_desc[i+1].len = len;
        tx_desc[i+1].addr = dma_addr;

        // update tx_info
        tx_info->frag_count = i+1;
        tx_info->frags[i].len = len;
        tx_info->frags[i].dma_addr = dma_addr;
    }

    for (i = tx_info->frag_count; i < ring->desc_block_size-1; i++)
    {
        tx_desc[i+1].len = 0;
        tx_desc[i+1].addr = 0;
    }

    // map skb
    len = skb_headlen(skb);
    dma_addr = dma_map_single(priv->dev, skb->data, len, PCI_DMA_TODEVICE);

    if (unlikely(dma_mapping_error(priv->dev, dma_addr)))
    {
        // mapping failed
        goto map_error;
    }

    // write descriptor
    tx_desc[0].len = len;
    tx_desc[0].addr = dma_addr;

    // update tx_info
    dma_unmap_addr_set(tx_info, dma_addr, dma_addr);
    dma_unmap_len_set(tx_info, len, len);

    return true;

map_error:
    dev_err(priv->dev, "mqnic_map_skb DMA mapping failed");

    // unmap frags
    for (i = 0; i < tx_info->frag_count; i++)
    {
        dma_unmap_page(priv->dev, tx_info->frags[i].dma_addr, tx_info->frags[i].len, PCI_DMA_TODEVICE);
    }

    // update tx_info
    tx_info->skb = NULL;
    tx_info->frag_count = 0;

    return false;
}

netdev_tx_t mqnic_start_xmit(struct sk_buff *skb, struct net_device *ndev)
{
    struct skb_shared_info *shinfo = skb_shinfo(skb);
    struct mqnic_priv *priv = netdev_priv(ndev);
    struct mqnic_ring *ring;
    struct mqnic_tx_info *tx_info;
    struct mqnic_desc *tx_desc;
    int ring_index;
    u32 index;
    bool stop_queue;
    u32 clean_tail_ptr;

    if (unlikely(!priv->port_up))
    {
        goto tx_drop;
    }

    ring_index = skb_get_queue_mapping(skb);

    if (unlikely(ring_index >= priv->tx_queue_count))
    {
        // queue mapping out of range
        goto tx_drop;
    }

    ring = priv->tx_ring[ring_index];

    clean_tail_ptr = READ_ONCE(ring->clean_tail_ptr);

    // prefetch for BQL
    netdev_txq_bql_enqueue_prefetchw(ring->tx_queue);

    index = ring->head_ptr & ring->size_mask;

    tx_desc = (struct mqnic_desc *)(ring->buf + index*ring->stride);

    tx_info = &ring->tx_info[index];

    // TX hardware timestamp
    tx_info->ts_requested = 0;
    if (unlikely(priv->if_features & MQNIC_IF_FEATURE_PTP_TS && shinfo->tx_flags & SKBTX_HW_TSTAMP)) {
        dev_info(priv->dev, "mqnic_start_xmit TX TS requested");
        shinfo->tx_flags |= SKBTX_IN_PROGRESS;
        tx_info->ts_requested = 1;
    }

    // TX hardware checksum
    if (skb->ip_summed == CHECKSUM_PARTIAL) {
        unsigned int csum_start = skb_checksum_start_offset(skb);
        unsigned int csum_offset = skb->csum_offset;

        if (csum_start > 255 || csum_offset > 127)
        {
            dev_info(priv->dev, "mqnic_start_xmit Hardware checksum fallback start %d offset %d", csum_start, csum_offset);

            // offset out of range, fall back on software checksum
            if (skb_checksum_help(skb))
            {
                // software checksumming failed
                goto tx_drop_count;
            }
            tx_desc->tx_csum_cmd = 0;
        }
        else
        {
            tx_desc->tx_csum_cmd = 0x8000 | (csum_offset << 8) | (csum_start);
        }
    }
    else
    {
        tx_desc->tx_csum_cmd = 0;
    }

    if (shinfo->nr_frags > ring->desc_block_size-1 || (skb->data_len && skb->data_len < 32))
    {
        // too many frags or very short data portion; linearize
        if (skb_linearize(skb))
        {
            goto tx_drop_count;
        }
    }

    // map skb
    if (!mqnic_map_skb(priv, ring, tx_info, tx_desc, skb))
    {
        // map failed
        goto tx_drop_count;
    }

    // count packet
    ring->packets++;
    ring->bytes += skb->len;

    // enqueue
    ring->head_ptr++;

    skb_tx_timestamp(skb);

    stop_queue = mqnic_is_tx_ring_full(ring);
    if (unlikely(stop_queue))
    {
        dev_info(priv->dev, "mqnic_start_xmit TX ring %d full on port %d", ring_index, priv->port);
        netif_tx_stop_queue(ring->tx_queue);
    }

    // BQL
    //netdev_tx_sent_queue(ring->tx_queue, tx_info->len);
    //__netdev_tx_sent_queue(ring->tx_queue, tx_info->len, skb->xmit_more);

    // enqueue on NIC
#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,2,0)
    if (unlikely(!netdev_xmit_more() || stop_queue))
#else
    if (unlikely(!skb->xmit_more || stop_queue))
#endif
    {
        dma_wmb();
        mqnic_tx_write_head_ptr(ring);
    }

    // check if queue restarted
    if (unlikely(stop_queue))
    {
        smp_rmb();

        clean_tail_ptr = READ_ONCE(ring->clean_tail_ptr);

        if (unlikely(!mqnic_is_tx_ring_full(ring)))
        {
            netif_tx_wake_queue(ring->tx_queue);
        }
    }

    return NETDEV_TX_OK;

tx_drop_count:
    ring->dropped_packets++;
tx_drop:
    dev_kfree_skb_any(skb);
    return NETDEV_TX_OK;
}
