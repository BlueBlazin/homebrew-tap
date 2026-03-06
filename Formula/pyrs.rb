require "digest"

class Pyrs < Formula
  desc "Python interpreter in Rust targeting CPython 3.14 compatibility"
  homepage "https://github.com/BlueBlazin/pyrs"
  version "0.4.3"

  on_macos do
    on_arm do
      url "https://github.com/BlueBlazin/pyrs/releases/download/v0.4.3/pyrs-v0.4.3-aarch64-apple-darwin.tar.gz"
      sha256 "9aeba9dc94910f878b9243d230904ba9c4403436317d45f5ed64947b51c13779"
    end

    on_intel do
      url "https://github.com/BlueBlazin/pyrs/releases/download/v0.4.3/pyrs-v0.4.3-x86_64-apple-darwin.tar.gz"
      sha256 "260250d76e9c74b849168a5fda34194750b58dd1504f03ec1fd9b909d03fb12b"
    end
  end

  head "https://github.com/BlueBlazin/pyrs.git", branch: "master"

  resource "pyrs-stdlib-cpython-3.14.3" do
    url "https://github.com/BlueBlazin/pyrs/releases/download/v0.4.3/pyrs-stdlib-cpython-3.14.3.tar.gz"
    sha256 "2569d074f1607166a14f0b67663daa1170d6b0181c30b4a5be095b8f25b9e337"
  end

  def install
    odie "pyrs Homebrew installs currently support macOS only" unless OS.mac?

    if build.head?
      nightly_checksums = fetch_nightly_checksums
      download_and_verify_nightly_asset(nightly_archive_name, nightly_checksums)
      system "tar", "-xzf", nightly_archive_name
      download_and_verify_nightly_asset(nightly_stdlib_archive_name, nightly_checksums)
      system "tar", "-xzf", nightly_stdlib_archive_name
    end

    bin.install "pyrs"

    if build.head?
      install_stdlib_tree(buildpath/"pyrs-stdlib-cpython-3.14.3")
    else
      resource("pyrs-stdlib-cpython-3.14.3").stage do
        install_stdlib_tree(Pathname.pwd)
      end
    end
  end

  def install_stdlib_tree(stdlib_root)
    stdlib_prefix = share/"pyrs/stdlib/3.14.3"
    stdlib_prefix.mkpath
    cp_r stdlib_root/"Lib", stdlib_prefix/"Lib"
    cp stdlib_root/"LICENSE", stdlib_prefix/"LICENSE"
    metadata_path = stdlib_root/"METADATA.txt"
    cp metadata_path, stdlib_prefix/"METADATA.txt" if metadata_path.exist?
  end

  def fetch_nightly_checksums
    return @nightly_checksums if @nightly_checksums

    checksum_path = buildpath/"SHA256SUMS"
    system "curl", "-fsSL", "https://github.com/BlueBlazin/pyrs/releases/download/nightly/SHA256SUMS", "-o", checksum_path

    @nightly_checksums = checksum_path.readlines(chomp: true).each_with_object({}) do |line, checksums|
      sha, name = line.split(/\s+/, 2)
      next unless sha && name
      checksums[name] = sha
    end
  end

  def download_and_verify_nightly_asset(archive_name, checksums)
    expected_sha = checksums[archive_name]
    odie "Missing SHA256 entry for #{archive_name} in nightly release" unless expected_sha

    archive_path = buildpath/archive_name
    nightly_url = "https://github.com/BlueBlazin/pyrs/releases/download/nightly/#{archive_name}"
    system "curl", "-fsSL", nightly_url, "-o", archive_path
    actual_sha = Digest::SHA256.file(archive_path).hexdigest
    odie "Checksum mismatch for #{archive_name}: expected #{expected_sha}, got #{actual_sha}" unless actual_sha == expected_sha
  end

  def nightly_stdlib_archive_name
    "pyrs-stdlib-cpython-3.14.3.tar.gz"
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
