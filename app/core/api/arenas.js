import fetchJson from "./fetch-json";

export const getUsableArenas = () => {
  return fetchJson('/db/level/-/arenas')
}
