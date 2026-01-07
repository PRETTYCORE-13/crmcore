defmodule Prettycore.Auth.Desencryptor do
  @moduledoc false

  @passphrase "Pas5pr@se"
  @salt "s@1tValue"
  @iv "@1B2c3D4e5F6g7H8"
  @hash_fun :sha
  @iterations 2
  @key_size_bits 0x100
  @block_size 16

  def encrypt(plain_text) when is_binary(plain_text) do
    plain_bytes = :unicode.characters_to_binary(plain_text, :utf8)
    salt_bytes = :unicode.characters_to_binary(@salt, :latin1)
    iv_bytes = :unicode.characters_to_binary(@iv, :latin1)

    key_len = div(@key_size_bits, 8)
    key = derive_key(@passphrase, salt_bytes, @hash_fun, @iterations, key_len)

    padded = pkcs7_pad(plain_bytes, @block_size)
    cipher = :crypto.crypto_one_time(:aes_256_cbc, key, iv_bytes, padded, true)

    Base.encode64(cipher)
  end

  def decrypt_base64(b64) when is_binary(b64) do
    case Base.decode64(b64) do
      {:ok, cipher} -> decrypt_bytes(cipher)
      :error -> {:error, :invalid_base64}
    end
  end

  # Opcional: versión que lanza o regresa nil
  def decrypt_base64!(b64) do
    case decrypt_base64(b64) do
      {:ok, plain} -> plain
      {:error, _} -> nil
    end
  end

  defp decrypt_bytes(cipher) when is_binary(cipher) do
    salt_bytes = :unicode.characters_to_binary(@salt, :latin1)
    iv_bytes = :unicode.characters_to_binary(@iv, :latin1)

    key_len = div(@key_size_bits, 8)
    key = derive_key(@passphrase, salt_bytes, @hash_fun, @iterations, key_len)

    try do
      plain_padded = :crypto.crypto_one_time(:aes_256_cbc, key, iv_bytes, cipher, false)

      case pkcs7_unpad(plain_padded, @block_size) do
        {:ok, plain} ->
          {:ok, :unicode.characters_to_binary(plain, :utf8)}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      _ -> {:error, :decrypt_failed}
    end
  end

  defp derive_key(passphrase, salt_bytes, hash_fun, iterations, key_len) do
    pwd_bytes = :unicode.characters_to_binary(passphrase, :utf8)

    base =
      Enum.reduce(1..max(iterations - 1, 1), pwd_bytes <> salt_bytes, fn _, acc ->
        :crypto.hash(hash_fun, acc)
      end)

    r1 = :crypto.hash(hash_fun, base)
    r2 = :crypto.hash(hash_fun, "1" <> base)

    (r1 <> r2)
    |> binary_part(0, key_len)
  end

  defp pkcs7_pad(data, block_size) do
    pad_len = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<pad_len>>, pad_len)
  end

  defp pkcs7_unpad(bin, block_size) when is_binary(bin) do
    size = byte_size(bin)

    if size == 0 do
      {:error, :invalid_padding}
    else
      <<_::binary-size(size - 1), last>> = bin
      pad_len = last

      cond do
        pad_len == 0 or pad_len > block_size or pad_len > size ->
          {:error, :invalid_padding}

        true ->
          <<data::binary-size(size - pad_len), padding::binary-size(pad_len)>> = bin

          if padding == :binary.copy(<<pad_len>>, pad_len) do
            {:ok, data}
          else
            {:error, :invalid_padding}
          end
      end
    end
  end
end
