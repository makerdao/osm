# ds-delay

DSValue with one hour delay.

Initialize with a `DSValue` source to read from.

```
DSDelay d = new DSDelay(DSValue(src));
```

If this `DSValue` has a valid value on creation, `ds-delay` with start with that same value.

After one hour has passed, `ds-delay` can be `poke`d. When this happens, the value queued will become the active `read` and `peek` value, and whatever value its `src` has will be queued as the next value.

Note: to test, comment the line

`warp(0);`