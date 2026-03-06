class Pyrs < Formula
  desc "Python interpreter in Rust targeting CPython 3.14 compatibility"
  homepage "https://github.com/BlueBlazin/pyrs"
  version "0.4.2"

  on_macos do
    on_arm do
      url "https://github.com/BlueBlazin/pyrs/releases/download/v0.4.2/pyrs-v0.4.2-aarch64-apple-darwin.tar.gz"
      sha256 "6d56a9d990464c38c6a24378ca470d227c1fecbaa884c4a0bb456efa535cc8ef"
    end

    on_intel do
      url "https://github.com/BlueBlazin/pyrs/releases/download/v0.4.2/pyrs-v0.4.2-x86_64-apple-darwin.tar.gz"
      sha256 "9a3b326df430a0c6348f595913af3bd257ee17bc6d40ceb91a08fc5b6afb18c0"
    end
  end

  head "https://github.com/BlueBlazin/pyrs.git", branch: "master"

  resource "cpython-stdlib-3.14.3" do
    url "https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tgz"
    sha256 "d7fe130d0501ae047ca318fa92aa642603ab6f217901015a1df6ce650d5470cd"
  end

  def install
    odie "pyrs Homebrew installs currently support macOS only" unless OS.mac?

    if build.head?
      nightly_url = "https://github.com/BlueBlazin/pyrs/releases/download/nightly/#{nightly_archive_name}"
      system "curl", "-fsSL", nightly_url, "-o", "pyrs-nightly.tar.gz"
      system "tar", "-xzf", "pyrs-nightly.tar.gz"
    end

    bin.install "pyrs"
    (share/"pyrs/stdlib/3.14.3").mkpath
    resource("cpython-stdlib-3.14.3").stage do
      cp_r "Lib", share/"pyrs/stdlib/3.14.3/Lib"
      cp "LICENSE", share/"pyrs/stdlib/3.14.3/LICENSE"
    end
  end

  def nightly_archive_name
    if Hardware::CPU.arm?
      "pyrs-nightly-aarch64-apple-darwin.tar.gz"
    elsif Hardware::CPU.intel?
      "pyrs-nightly-x86_64-apple-darwin.tar.gz"
    else
      odie "Unsupported macOS CPU architecture"
    end
  end

  test do
    stdlib = share/"pyrs/stdlib/3.14.3/Lib"
    assert_match "pyrs", shell_output("#{bin}/pyrs --version")
    assert_equal "ok\n", shell_output("#{bin}/pyrs -c 'import json, os; bundle = os.path.normpath(#{stdlib.to_s.inspect}); jf = os.path.normpath(getattr(json, \"__file__\", \"\")); assert jf.startswith(bundle), (bundle, jf); print(\"ok\")'")
  end
end
