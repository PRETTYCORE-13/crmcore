defmodule Prettycore.Auth.Encryptor do
  @moduledoc false

  @passphrase "Pas5pr@se"
  @salt "s@1tValue"
  @iv "@1B2c3D4e5F6g7H8"
  @hash_alg "SHA1"
  @iterations 2
  # 256 bits
  @key_size_bits 0x100
  # AES block = 128 bits
  @block_size 16

  # ==========================
  # Cifrado equivalente a FROG.Encrypt(string)
  # ==========================
  def encrypt(plain_text) do
    encrypt_internal(
      plain_text,
      @passphrase,
      @salt,
      @hash_alg,
      @iterations,
      @iv,
      @key_size_bits
    )
  end

  # --------------------------

  defp encrypt_internal(
         plain_text,
         passphrase,
         salt_value,
         hash_algorithm,
         password_iterations,
         init_vector,
         key_size_bits
       ) do
    # 1. Texto plano en UTF-8
    plain_bytes = :unicode.characters_to_binary(plain_text, :utf8)

    # 2. Salt y IV en ASCII (parUseUTF8 = False)
    salt_bin = :unicode.characters_to_binary(salt_value, :latin1)
    iv_bin = :unicode.characters_to_binary(init_vector, :latin1)

    # 3. Derivar clave como PasswordDeriveBytes(pass, salt, SHA1, 2)
    key_len = div(key_size_bits, 8)
    key = derive_pdb_key(passphrase, salt_bin, hash_algorithm, password_iterations, key_len)

    # 4. AES-256-CBC + PKCS7
    padded = pkcs7_pad(plain_bytes, @block_size)
    cipher = :crypto.crypto_one_time(:aes_256_cbc, key, iv_bin, padded, true)

    # 5. Resultado Base64
    Base.encode64(cipher)
  end

  # --------------------------

  # PasswordDeriveBytes clone (SHA1, 2 iterations)
  defp derive_pdb_key(passphrase, salt_bytes, "SHA1", iterations, key_len) do
    pwd_bytes = :unicode.characters_to_binary(passphrase, :latin1)

    # base = H(pass+salt) + H(base) ... iter veces
    base =
      Enum.reduce(1..max(iterations - 1, 1), pwd_bytes <> salt_bytes, fn _, acc ->
        :crypto.hash(:sha, acc)
      end)

    r1 = :crypto.hash(:sha, base)
    r2 = :crypto.hash(:sha, "1" <> base)

    (r1 <> r2)
    |> binary_part(0, key_len)
  end

  defp pkcs7_pad(data, block_size) do
    pad_len = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<pad_len>>, pad_len)
  end
end
