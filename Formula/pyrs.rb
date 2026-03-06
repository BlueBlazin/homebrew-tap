class Pyrs < Formula
  desc "Python interpreter in Rust targeting CPython 3.14 compatibility"
  homepage "https://github.com/BlueBlazin/pyrs"
  url "https://github.com/BlueBlazin/pyrs/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "dbc59a9265c59cb091b3a1878b7d14cd587b586e950800e6044d9d982161af15"
  head "https://github.com/BlueBlazin/pyrs.git", branch: "master"

  depends_on "rust" => :build

  resource "cpython-stdlib-3.14.3" do
    url "https://www.python.org/ftp/python/3.14.3/Python-3.14.3.tgz"
    sha256 "d7fe130d0501ae047ca318fa92aa642603ab6f217901015a1df6ce650d5470cd"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "."), "--locked"
    (share/"pyrs/stdlib/3.14.3").mkpath
    resource("cpython-stdlib-3.14.3").stage do
      cp_r "Lib", share/"pyrs/stdlib/3.14.3/Lib"
      cp "LICENSE", share/"pyrs/stdlib/3.14.3/LICENSE"
    end
  end

  test do
    stdlib = share/"pyrs/stdlib/3.14.3/Lib"
    assert_match "pyrs", shell_output("#{bin}/pyrs --version")
    assert_equal "ok\n", shell_output("#{bin}/pyrs -c 'import json, os; bundle = os.path.normpath(#{stdlib.to_s.inspect}); jf = os.path.normpath(getattr(json, \"__file__\", \"\")); assert jf.startswith(bundle), (bundle, jf); print(\"ok\")'")
  end
end
