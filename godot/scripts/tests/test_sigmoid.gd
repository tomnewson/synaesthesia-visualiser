extends GutTest

const EPSILON = 0.0001 # Small value for floating point comparison

# Test that sigmoid returns half of val_max at middle of range
func test_sigmoid_at_middle():
	var result = Globals.sigmoid(63.5, 0.0, 127.0)
	assert_almost_eq(result, 63.5, EPSILON)

func test_sigmoid_at_min():
	var result = Globals.sigmoid(0.0, 0.0, 127.0)
	assert_almost_eq(result, 0.0, EPSILON * 10_000)

func test_sigmoid_at_max():
	var result = Globals.sigmoid(127.0, 0.0, 127.0)
	assert_almost_eq(result, 127.0, EPSILON * 10_000)

# Test that sigmoid approaches val_max for values near max
func test_sigmoid_approaches_max():
	var result = Globals.sigmoid(100.0, 0.0, 127.0)
	assert_gt(result, 120.0)
	assert_lt(result, 125.0)

# Test that sigmoid approaches val_mmin for values near min
func test_sigmoid_approaches_min():
	var result = Globals.sigmoid(27.0, 0.0, 127.0)
	assert_lt(result, 7.0)
	assert_gt(result, 2.0)
