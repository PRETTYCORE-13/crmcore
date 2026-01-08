# Load environment variables from .env file
env_file = Path.expand(".env", File.cwd!())

if File.exists?(env_file) do
  File.stream!(env_file)
  |> Stream.map(&String.trim/1)
  |> Stream.reject(&(String.starts_with?(&1, "#") or &1 == ""))
  |> Enum.each(fn line ->
    case String.split(line, "=", parts: 2) do
      [key, value] ->
        System.put_env(key, value)
      _ ->
        :ok
    end
  end)
end
