for i in range(2 ** 15):
    print(format((i & 0xFF) ^ (i >> 8), "X"))