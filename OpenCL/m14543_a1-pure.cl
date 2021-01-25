/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//#define NEW_SIMD_CODE

#ifdef KERNEL_STATIC
#include "inc_vendor.h"
#include "inc_types.h"
#include "inc_platform.cl"
#include "inc_common.cl"
#include "inc_scalar.cl"
#include "inc_hash_ripemd160.cl"
#include "inc_cipher_twofish.cl"
#endif

typedef struct cryptoapi
{
  u32 kern_type;
  u32 key_size;

} cryptoapi_t;

KERNEL_FQ void m14543_mxx (KERN_ATTR_ESALT (cryptoapi_t))
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);

  if (gid >= gid_max) return;

  /**
   * base
   */

  u32 twofish_key_len = esalt_bufs[DIGESTS_OFFSET].key_size;

  u32 padding[64] = { 0 };

  padding[0] = 0x00000041;

  ripemd160_ctx_t ctx0, ctx0_padding;

  ripemd160_init (&ctx0);

  u32 w[64] = { 0 };

  u32 w_len = 0;

  if (twofish_key_len > 128)
  {
    w_len = pws[gid].pw_len;

    for (u32 i = 0; i < 64; i++) w[i] = pws[gid].i[i];

    ctx0_padding = ctx0;

    ripemd160_update (&ctx0_padding, padding, 1);

    ripemd160_update (&ctx0_padding, w, w_len);
  }

  ripemd160_update_global (&ctx0, pws[gid].i, pws[gid].pw_len);

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    ripemd160_ctx_t ctx = ctx0;

    if (twofish_key_len > 128)
    {
      w_len = combs_buf[il_pos].pw_len;

      for (u32 i = 0; i < 64; i++) w[i] = combs_buf[il_pos].i[i];
    }

    ripemd160_update_global (&ctx, combs_buf[il_pos].i, combs_buf[il_pos].pw_len);

    ripemd160_final (&ctx);

    const u32 k0 = ctx.h[0];
    const u32 k1 = ctx.h[1];
    const u32 k2 = ctx.h[2];
    const u32 k3 = ctx.h[3];

    u32 k4 = 0, k5 = 0, k6 = 0, k7 = 0;

    if (twofish_key_len > 128)
    {
      k4 = ctx.h[4];

      ripemd160_ctx_t ctx0_tmp = ctx0_padding;

      ripemd160_update (&ctx0_tmp, w, w_len);

      ripemd160_final (&ctx0_tmp);

      k5 = ctx0_tmp.h[0];

      if (twofish_key_len > 192)
      {
        k6 = ctx0_tmp.h[1];
        k7 = ctx0_tmp.h[2];
      }
    }

    // key

    u32 ukey[8] = { 0 };

    ukey[0] = k0;
    ukey[1] = k1;
    ukey[2] = k2;
    ukey[3] = k3;

    if (twofish_key_len > 128)
    {
      ukey[4] = k4;
      ukey[5] = k5;

      if (twofish_key_len > 192)
      {
        ukey[6] = k6;
        ukey[7] = k7;
      }
    }

    // IV

    const u32 iv[4] = { 0x00000003, 0x00000000, 0x00000000, 0x00000000 };

    // CT

    u32 CT[4] = { 0 };

    // twofish

    u32 sk1[4] = { 0 };
    u32 lk1[40] = { 0 };

    if (twofish_key_len == 128)
    {
      twofish128_set_key (sk1, lk1, ukey);

      twofish128_encrypt (sk1, lk1, iv, CT);
    }
    else if (twofish_key_len == 192)
    {
      twofish192_set_key (sk1, lk1, ukey);

      twofish192_encrypt (sk1, lk1, iv, CT);
    }
    else
    {
      twofish256_set_key (sk1, lk1, ukey);

      twofish256_encrypt (sk1, lk1, iv, CT);
    }

    const u32 r0 = hc_swap32_S (CT[0]);
    const u32 r1 = hc_swap32_S (CT[1]);
    const u32 r2 = hc_swap32_S (CT[2]);
    const u32 r3 = hc_swap32_S (CT[3]);

    COMPARE_M_SCALAR (r0, r1, r2, r3);
  }
}

KERNEL_FQ void m14543_sxx (KERN_ATTR_ESALT (cryptoapi_t))
{
  /**
   * modifier
   */

  const u64 gid = get_global_id (0);

  if (gid >= gid_max) return;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[DIGESTS_OFFSET].digest_buf[DGST_R0],
    digests_buf[DIGESTS_OFFSET].digest_buf[DGST_R1],
    digests_buf[DIGESTS_OFFSET].digest_buf[DGST_R2],
    digests_buf[DIGESTS_OFFSET].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  u32 twofish_key_len = esalt_bufs[DIGESTS_OFFSET].key_size;

  u32 padding[64] = { 0 };

  padding[0] = 0x00000041;

  ripemd160_ctx_t ctx0, ctx0_padding;

  ripemd160_init (&ctx0);

  u32 w[64] = { 0 };

  u32 w_len = 0;

  if (twofish_key_len > 128)
  {
    w_len = pws[gid].pw_len;

    for (u32 i = 0; i < 64; i++) w[i] = pws[gid].i[i];

    ctx0_padding = ctx0;

    ripemd160_update (&ctx0_padding, padding, 1);

    ripemd160_update (&ctx0_padding, w, w_len);
  }

  ripemd160_update_global (&ctx0, pws[gid].i, pws[gid].pw_len);

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    ripemd160_ctx_t ctx = ctx0;

    if (twofish_key_len > 128)
    {
      w_len = combs_buf[il_pos].pw_len;

      for (u32 i = 0; i < 64; i++) w[i] = combs_buf[il_pos].i[i];
    }

    ripemd160_update_global (&ctx, combs_buf[il_pos].i, combs_buf[il_pos].pw_len);

    ripemd160_final (&ctx);

    const u32 k0 = ctx.h[0];
    const u32 k1 = ctx.h[1];
    const u32 k2 = ctx.h[2];
    const u32 k3 = ctx.h[3];

    u32 k4 = 0, k5 = 0, k6 = 0, k7 = 0;

    if (twofish_key_len > 128)
    {
      k4 = ctx.h[4];

      ripemd160_ctx_t ctx0_tmp = ctx0_padding;

      ripemd160_update (&ctx0_tmp, w, w_len);

      ripemd160_final (&ctx0_tmp);

      k5 = ctx0_tmp.h[0];

      if (twofish_key_len > 192)
      {
        k6 = ctx0_tmp.h[1];
        k7 = ctx0_tmp.h[2];
      }
    }

    // key

    u32 ukey[8] = { 0 };

    ukey[0] = k0;
    ukey[1] = k1;
    ukey[2] = k2;
    ukey[3] = k3;

    if (twofish_key_len > 128)
    {
      ukey[4] = k4;
      ukey[5] = k5;

      if (twofish_key_len > 192)
      {
        ukey[6] = k6;
        ukey[7] = k7;
      }
    }

    // IV

    const u32 iv[4] = { 0x00000003, 0x00000000, 0x00000000, 0x00000000 };

    // CT

    u32 CT[4] = { 0 };

    // twofish

    u32 sk1[4] = { 0 };
    u32 lk1[40] = { 0 };

    if (twofish_key_len == 128)
    {
      twofish128_set_key (sk1, lk1, ukey);

      twofish128_encrypt (sk1, lk1, iv, CT);
    }
    else if (twofish_key_len == 192)
    {
      twofish192_set_key (sk1, lk1, ukey);

      twofish192_encrypt (sk1, lk1, iv, CT);
    }
    else
    {
      twofish256_set_key (sk1, lk1, ukey);

      twofish256_encrypt (sk1, lk1, iv, CT);
    }

    const u32 r0 = hc_swap32_S (CT[0]);
    const u32 r1 = hc_swap32_S (CT[1]);
    const u32 r2 = hc_swap32_S (CT[2]);
    const u32 r3 = hc_swap32_S (CT[3]);

    COMPARE_S_SCALAR (r0, r1, r2, r3);
  }
}
