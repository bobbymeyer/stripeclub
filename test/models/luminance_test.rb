require "test_helper"

class LuminanceTest < ActiveSupport::TestCase
  # The three sRGB primaries as OKLab publishes them. If the matrices or the
  # cube roots are wrong these are the numbers that move, and they are quoted
  # rather than computed so the test does not agree with the code by
  # construction.
  test "the sRGB primaries land where OKLab says they do" do
    assert_in_delta 0.627955, Luminance.of(255, 0, 0), 1e-6
    assert_in_delta 0.866440, Luminance.of(0, 255, 0), 1e-6
    assert_in_delta 0.452014, Luminance.of(0, 0, 255), 1e-6
  end

  # White comes out at 0.99999999347, not at one. That is the spec's own
  # arithmetic: the coefficients are published to ten places and do not quite
  # weigh back to unity through the cube roots. The tolerance is set to admit
  # exactly that and nothing looser, because a real error in the matrix would
  # move this number in the sixth place, not the ninth.
  test "black is nothing and white is everything, to the constants' own precision" do
    assert_in_delta 0.0, Luminance.of(0, 0, 0), 1e-12
    assert_in_delta 1.0, Luminance.of(255, 255, 255), 1e-8
  end

  # Half of 255 is not half the light. A mid gray reads at .60 rather than
  # .50, and any measure that puts it at .50 has skipped the gamma.
  test "mid gray is not half way" do
    assert_in_delta 0.599871, Luminance.of(128, 128, 128), 1e-6
  end

  # The reason for using a perceptual measure at all. Yellow and blue are the
  # same distance from black by channel sum and nowhere near it by eye.
  test "yellow reads lighter than blue" do
    assert_operator Luminance.of(255, 255, 0), :>, Luminance.of(0, 0, 255)
  end

  test "luminance rises with the gray it measures" do
    grays = (0..255).step(15).map { |level| Luminance.of(level, level, level) }

    assert_equal grays.sort, grays
  end

  # its-swiss states its value scale in OKLCH lightness: --value-0 at 98% and
  # --value-5 at 18%. Measuring the hex those resolve to gets the same two
  # numbers back, which is the check that this module and the library are
  # talking about the same quantity.
  test "the library's own value scale measures as the lightness it declares" do
    assert_in_delta 0.98, Luminance.of_hex("#FAF8F4"), 0.005
    assert_in_delta 0.18, Luminance.of_hex("#12120F"), 0.005
  end

  test "a hex is read in either spelling" do
    assert_equal Luminance.of(255, 255, 0), Luminance.of_hex("#FFFF00")
    assert_equal Luminance.of(255, 255, 0), Luminance.of_hex("ffff00")
  end
end
