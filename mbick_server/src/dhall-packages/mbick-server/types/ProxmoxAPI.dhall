let networking = ../../networking/types.dhall

-- in {
-- , host :
--     networking.HostAddress
-- , url :
--     Text
-- , base_url :
--     Text
-- }

in {
, address :
    networking.HostURL
}
