# Documentation: https://docs.brew.sh/Formula-Cookbook
#                https://rubydoc.brew.sh/Formula
# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class RocketmqConsoleNg < Formula
  desc "rocketmq_console"
  homepage ""
  url "https://github.com/mayuzhou/homebrew-tap/blob/master/realses/rocketmq-console-ng-1.0.0.jar"
  sha256 "3dfea944a4ad86684829f41a615e61ac74490fae57676481d7453f3e37329ea0"

  # depends_on "cmake" => :build

  

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test rocketmq-console-ng`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
