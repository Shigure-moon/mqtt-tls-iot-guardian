--
-- PostgreSQL database dump
--

-- Dumped from database version 14.17 (Debian 14.17-1.pgdg120+1)
-- Dumped by pg_dump version 14.17 (Debian 14.17-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: access_control_policies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_control_policies (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    device_id uuid NOT NULL,
    topic_pattern character varying(255) NOT NULL,
    action character varying(20) NOT NULL,
    effect character varying(10) NOT NULL,
    conditions json,
    priority integer DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.access_control_policies OWNER TO postgres;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO postgres;

--
-- Name: alert_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_rules (
    id character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    device_id uuid,
    metric_type character varying NOT NULL,
    metric_name character varying NOT NULL,
    condition character varying NOT NULL,
    threshold real NOT NULL,
    severity character varying NOT NULL,
    message character varying NOT NULL,
    enabled boolean DEFAULT true,
    priority integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.alert_rules OWNER TO postgres;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    alert_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    message text NOT NULL,
    status character varying(20) NOT NULL,
    acknowledged boolean NOT NULL,
    acknowledged_by uuid,
    acknowledged_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- Name: blacklisted_ips; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.blacklisted_ips (
    id uuid NOT NULL,
    ip_address inet NOT NULL,
    reason text,
    expiry_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.blacklisted_ips OWNER TO postgres;

--
-- Name: device_certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_certificates (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    certificate character varying NOT NULL,
    private_key character varying,
    certificate_type character varying(20) NOT NULL,
    serial_number character varying(100) NOT NULL,
    issued_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    revoke_reason character varying(100),
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.device_certificates OWNER TO postgres;

--
-- Name: device_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_data (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    data_type character varying(50) NOT NULL,
    value json NOT NULL,
    quality character varying(20)
);


ALTER TABLE public.device_data OWNER TO postgres;

--
-- Name: device_encryption_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_encryption_keys (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    key_encrypted text NOT NULL,
    key_hash character varying(64) NOT NULL,
    created_by uuid,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.device_encryption_keys OWNER TO postgres;

--
-- Name: device_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_logs (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    log_type character varying(50) NOT NULL,
    message character varying NOT NULL,
    log_metadata json,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.device_logs OWNER TO postgres;

--
-- Name: device_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_metrics (
    id character varying NOT NULL,
    device_id uuid NOT NULL,
    metric_type character varying NOT NULL,
    metrics json NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
);


ALTER TABLE public.device_metrics OWNER TO postgres;

--
-- Name: device_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_templates (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    device_type character varying(50) NOT NULL,
    description character varying(500),
    template_code text NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    created_by uuid,
    version character varying(20) DEFAULT 'v1'::character varying NOT NULL,
    required_libraries text
);


ALTER TABLE public.device_templates OWNER TO postgres;

--
-- Name: devices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.devices (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    device_id character varying(100) NOT NULL,
    type character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    attributes json,
    last_online_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.devices OWNER TO postgres;

--
-- Name: firmware_builds; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.firmware_builds (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    firmware_path character varying(512) NOT NULL,
    firmware_hash character varying(64) NOT NULL,
    firmware_size character varying(20) NOT NULL,
    encrypted_firmware_path character varying(512),
    encrypted_firmware_hash character varying(64),
    build_type character varying(20) DEFAULT 'encrypted'::character varying NOT NULL,
    encryption_key_id uuid,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    created_by uuid,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.firmware_builds OWNER TO postgres;

--
-- Name: monitoring_alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.monitoring_alerts (
    id character varying NOT NULL,
    device_id uuid NOT NULL,
    rule_id character varying NOT NULL,
    metrics_id character varying NOT NULL,
    severity character varying NOT NULL,
    message character varying NOT NULL,
    status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    acknowledged_at timestamp without time zone,
    acknowledged_by uuid,
    resolved_at timestamp without time zone,
    resolved_by uuid
);


ALTER TABLE public.monitoring_alerts OWNER TO postgres;

--
-- Name: ota_update_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ota_update_tasks (
    id uuid NOT NULL,
    device_id uuid NOT NULL,
    firmware_build_id uuid,
    firmware_url character varying(512) NOT NULL,
    firmware_version character varying(50),
    firmware_hash character varying(64),
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    progress character varying(20) DEFAULT '0%'::character varying NOT NULL,
    error_message text,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.ota_update_tasks OWNER TO postgres;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id uuid NOT NULL,
    name character varying(50) NOT NULL,
    description character varying,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: security_audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.security_audit_logs (
    id uuid NOT NULL,
    log_type character varying(50) NOT NULL,
    actor_id uuid,
    actor_type character varying(20),
    target_id uuid,
    target_type character varying(20),
    action character varying(50) NOT NULL,
    status character varying(20) NOT NULL,
    ip_address inet,
    user_agent text,
    details json,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.security_audit_logs OWNER TO postgres;

--
-- Name: security_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.security_events (
    id uuid NOT NULL,
    event_type character varying(50) NOT NULL,
    severity character varying(20) NOT NULL,
    source_ip inet,
    device_id uuid,
    description text NOT NULL,
    raw_data json,
    handled boolean DEFAULT false NOT NULL,
    handler_id uuid,
    handled_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.security_events OWNER TO postgres;

--
-- Name: server_certificates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.server_certificates (
    id uuid NOT NULL,
    certificate character varying NOT NULL,
    private_key character varying NOT NULL,
    common_name character varying(255) NOT NULL,
    serial_number character varying(100) NOT NULL,
    issued_at timestamp with time zone NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    revoke_reason character varying(100),
    created_by uuid,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.server_certificates OWNER TO postgres;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    full_name character varying(100),
    mobile character varying(20),
    is_active boolean NOT NULL,
    is_admin boolean NOT NULL,
    totp_secret character varying(32),
    failed_attempts integer NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: access_control_policies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.access_control_policies (id, name, description, device_id, topic_pattern, action, effect, conditions, priority, enabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alembic_version (version_num) FROM stdin;
add_template_version
\.


--
-- Data for Name: alert_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_rules (id, name, description, device_id, metric_type, metric_name, condition, threshold, severity, message, enabled, priority, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, device_id, alert_type, severity, message, status, acknowledged, acknowledged_by, acknowledged_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: blacklisted_ips; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.blacklisted_ips (id, ip_address, reason, expiry_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: device_certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_certificates (id, device_id, certificate, private_key, certificate_type, serial_number, issued_at, expires_at, revoked_at, revoke_reason, created_at) FROM stdin;
12f58370-edd4-44bd-b3b5-5e11974f6af1	8697991c-4de3-4a5c-9961-ba73acfb61f4	Z0FBQUFBQnBDWkxjX1IwLWF3VWh2bXY2Z0ZxYlp4VjFTU0wtd0ZFaTFkUTBVak1JLTdGdnZNNVpUSXMxSHRUVDhXMlVGeWY2ajBtUlM4Ym80RndnSlM1ejZkWEpKV0dHX0tKVkVKV1Nld2RaRzFiZUplUHppT3pvbmpEVkp6ZEs2Ql9JZlRQN0tEVTltTlNJdmtGQ05EM3J6Rk5uNDhPZGhCcmwyZEl3cXROam0tRzEtSmtOQTg5dUZPSHVIRTFMTlMtUGpoSk53YWxEV2UzY2Z3dGR5azludHpGdGVGaVlvM0pyWnpiRExWSmk2Y0x0OWVyUE5nNVFPOGw3eHg3LWFXMDlVdnduSUxsVGgzLVRkc2pCRHgwaUJMMGUxOWRzMU82YXY1ZmNRbHMxeHNsZUVJOGZpeGZtR2ZVY1VJRVljNkRXS1F1N0dtLTgyeTg5RWNoMzlRZFBGSFZDNDVOc3A1SEZmLVlLYVZtZ3FoVHQ2SWdabkVGT293OFo1WEZFUGVZcFdqaVJpOFItQ05sRENoS2Y5cVZKaThaRUdhd0VYelFnSEhNVUQ1X2dqSDZQTTlZYmk0LWRzd1IwRzdoazVvZXdDZ1JoM21RZUo1cERhWjR2RGxiUHJqNElQbFhpMTIwZHNyLUVEbmJXWHB3QTRvc01oVFk1UVliVEJGcmw5ZTZqc2VDQko3ZW41T3hGU2VpZ3pnbEExbS1rQXhjSjRaaWtmYnUtT1M1b1hJQ0RKRllmSlJfVFFndVRWYnVMOHZVeWJDbkJsRXBWOHREQ04wOGNDTkNwb3JDSFdtMzVibGlsQ3NpdU9kTjI2YTczX3pwalFnaTNCS3lTbXhxaXJxSjhSdlJvU2hVRzBabXp5dktGdUltRGI4emhNcHV1Umk0VTRKMjJHTng5R1dUeThzTDVxek5hYy1VbDI4ZGRBa3RQZW5UazFxMGFjdWhORkhpX29WODlORTlraDRYeVRvNmN4eXFleF9pNm5ORlNoWUpMMFBMOUpyNmpwV0lkYVFibTBiR01kMFRjYjdjbE1SWF9uOE8xcHVmZHcwX2pmNmVwS0ZseDZhaUhOeHEwem53QnRETEgyblFpRzQyeUdHXy1lcmFlN2hOdFZfQmdTR0Z6aHdKa09BMmw3N1RUcm01amNIVlR4cWFJMmVodjJta2gyVEN2YTlnMEhrRTBzZ0x4Q0xXTzJzbWt1clh3aG9POE85V3U0czdLM01WZV9MaHhRcmNoOXoyYjNmcUdISVZGc0pOeUtaRmJrUjcwYVpUTEFRSTdiQkJydVp6Z0ROWFNKekhMRnVJZUkxeU1vSkt2S0lrLUFwMWlBYzlVUzk0Q0tIa2wtYjhFS0MyVE9FYVdGMHUybW1lU3hZcXpGMmNCS3ltYVYtYlFhemhXTk5abkJ5WElkN1VuVGxaNEhBTm43Ul94bVY3VFRaRzVrY3UzcFpiVVB3eW5SYmpnaVFLMy1ENEdCcXBKMWZyTkpxM1JZNFVvYmxCbXdjcW5OMWkzSld4V09Nbmp2TkhhdGF2MEYwWTFjOVNnbkFGclBQbE9FQlRvcXFzWkNjWTJwci1jd1gwZk95NWNRaE1iaVVieW5sWUNGbnhIUWJGNE82U05SS2g3NlhlLUZTaTAtaWtkd3NNNDFxYjdWd2ZEaGRWaWFURGZmdTBPTjFtTXpGd3d2elE3ZUNSUnRLNUJuNEFxbnBnOTBZLTlEMEZ0ZTdnNzh2cHEtOXd0YnZxQnAzd3pBWnZNc2NOQTl4ZWxKQmJvOUczVlYxbkM4N3VxREdIb2N4QzQ3NDMyUXhSVXF5VVNrR2s5RkxjejF6NW9qRlk4SXU4aDl5cmNwZzBEV1FkeGlZUjN1T2dFMW1KM3ZCN01Qc2FIenRkWjhwSkFSZUdUZURkV3FCTG1JcHhTaE5qOHN2RjAxcC1ORkVPWmUzRGVvS2dRc0hPcWpwSlhlVVpLUTR3Zk05QjlyY2R2WDZBMUtOVC05RnoteV9LTk5xaklHdjdiNTJWQ29yUkdoU05UdnRWWFFYWjlrVHl5UTc5SzJMTWZyVHlpclF1M09ZNGRiQ2FaTW5KdGNqNE9ZcU1zUGtoME1WN2FCR2tfdmlranM4djdXbmxBNzlxZFNESk0zYkQ2SVkxZGk5MHI4SEUwZnk5MVhQUWFwc0NzRFkxZHNBNEZ4b1g2OFVRUHFJTk1HVk1mcXVIYnhoMjVDa2NCQVNZY3RFY0NiVTI4UDBYaUp0Unk3eXhkZWpZU1VtYzF3NmFwNXQwZGRmT1FkRTVxNkF4VVpSMkRtQTRrYUFnNW9lOGxXaHQtWFhhVUl1Z1hwM054dVdRYlRhT2FVay0tZUJ5emk4c2RHbm1RVjdQeVZDaTEwellucThiSGpoVWlpZE1ieHlOODhZaDNsYm84SE4tcm9JcFRBZ2otLWlSeU0zMGQtSk80VTdKVGlDczRzNVE9	Z0FBQUFBQnBDWkxjcmVoVExVVEZ4S1lvSTBtWjM3ODlkSElmTXhIYVZkMFY4SC1DUTJhYVFHT3B1WFdRSU5Cc3dJcVlva05ET0o3VUdpU0RlWE1nZzlmWUFtNm9OcnhYMDlkZUt1R0ZfdGJYTEk2cFZ0eV8tYmp3N0JoOGZ1RVYzeDhFY3hMcHdIZlh5WTVpeXNHVFlTczhCZ3ZTRXNPR1pLUklOVGIzQzhkVzAzY1I0TXcyODhFVXlrYWljZTNQT1V6OVJLRGNSWWVtM0tscHV6Z3pPeGVJamNNS0V1MWpoTVBDd2pPY1VZN0pydjhEZXVtVFh5cEk1dVZxQzExVzNfT3FrNWJqTFptcjcwSnhQR2ZjSDE3ZXFTaDJmU2owaU9lYWxZNWp1N2c0SERCUC1pMTNiT2dQRE1lV25LMnAybm1rQWdzcDJyRGtxZlRyM3VuUjZfT1lTaUFqd3Mzdmd2bnp4NlpUSjQ5REVXZHh1bmtrLXAzcjlmRjZJOTB2ZTU3LWFYRGdMNXVLNGljemNkMnFEVUZ0SE9WT2szYTNRUmhvN18yUzY0a3RUTGI0OWJJSWZ1bGRvdUtTdk5SS09GdGlKSm9oRkVWZ2JtSnpUeTFJbkk1RDNjM25YZmszc0h4d2NPN1UxWXdJSmRPNkhyUGloZWtBMHgzOUVRTXlGX2NsYUlRV093NDRvR1RrRF9NYWg1NHlFaGZ4elhwU040U2FIM2lPYlZDS2N2dURHeElZc2ZONUZhRWhaQm5YUkJJVDRrZWhCOWFzeXdRVVV3VHd5N1ZYb0RSdnVKSkJTTDlhWUV0ZWJpZ0VqTE1PZHhMNVZFNjRJYndmTUtIQkw4MUJ1SDNfUDhqVDBINnM0UHlrb05yNnlhcWZGcUppMUpoSnFWYVEwemlCMWZRa19TNkVzemo3TE5kSFBYTUlHWmJWS2l3Qzd4c3RjTkM5dVBDbm1Bc3Rsb0J5ekVQT3VHR2RDYWxmcE1LT3JfbENPNl9QTzJBd01CMFZIMmc3djJHdmp1XzBuVHktR3ptUE9tWm91R1pDdldWR1ZBb0JEZ08yN1lWZTZoTktzblpiRzhSMTlyQzlkVGRaa0dNXzMzT1ZScjFXYVo3SzltLUw4WEhVZmdjWW9fb1Z0NGxvVUlKOG5sRHpkSjg5Ykg5YlFMM0ROVkJvbVp3cmU0cTJrR19nWUZZY2VzQnd2aGZjdjNHa2VnbE5keE10Q2o3YVkwWDF2QW94THdZTmkxdWt5NkZMbzFSNWFxcWc3MndLRkVOcEZya2ctbmJCMy00RnNWY21tbk5VN0taU0lYbW5uaUZPYTJYN2ROUmRPclJ5NmV1Q0pTRFo1eDF2S0NJNXotbElpZmdRZ2VSSl81czFUVXpDcXlCR0pWWmIxVURveExCMVF1V01PQ2NHaWJNa1VDNXNpemNkbjBCYkh4c0JnQV9oTlNNU19val8wNmtyR09TcUd1RUlncURNUGZWNXdJQklzeUh4M3VhSzNvcWhVU1ktYWw5UU1lTUdUb3VPMldZVUFPUTNlR0hHWXMxTkxGSDF1ekVGOVVHWDg3WGFjYXV0Ykk3Vkl5d3lmYWt5Ym10MXdsSTMxSGEwY01iRVhYM25Fakt1TUx1NEgyMjlFcmN3cnNxSjY0a0VPdmtCSDlPWGRnemxqVy1kbU9xN2FLTVVZM3BxallJblZ2VFZFSkFoZ3dVbW5lbHFWQ2hKZlVfQ29wMGpTZXI5U1NtWjc0ajRZckJOMHFuNHN1M3lteHVRZjNzdG9fYmE1VG5ZRk45M3UyVWVPOWRQTU5yYzIyV1JHRkJVSjhuVTh3cFZUY1NFNDJieVpvRFZ5UVZ0RlA0NjlTeUxJX18tUU10ZFdrVzctR1hpUjVVdDc0d1NkY2FxcDQzWkVCaS13YXZfTTdVYTdiWW9aeGFHNHZQb3ZOOWRoeU5UWHVValc1Mmd3MDBBOExVdW5SSFE2dkRNLWNXQTN2VjBScVh5VEloZ1lQYlZlbjJ2X2dHUEZXbTJWdEZQRmZ5di1ZVzJ2WERTMmtHLUhpN2tVM3VzdnJ0QlBjdW1QbDR0SWxhWU9nUEdHYURYNG12Z1VVbWhlaW9Vb1dCcmM0WEwtTGc4Vm1KTkpVMDNRZHBGTk9kT3o0b2hNSmhnb0huOWVIUENFanJkbzNzWGNoYkJFSTNpNXl5ZTBpWmVhMlJZNGRfMlpLYXNVR3NaVW9ScU1hSjRSTTFzZkVQOWcyU1JRQnFubmU5MWkxaTNDbjd5SFJmRUV5Q3pUX2pVZHNxREJFblJNbTUzai1rTlpycWhrSkVlNU83UDcxMUtyRnBuV0xDRHlSb2tfN1VsRXBsblo1SUs1MVhUa09oWV9vLXIwRTVoT3h5T2lqODgzYmFqd1F1MkdOV2tRNlNhc3hsdnhweVNQTVM1LVliQy1SNk8wT3dCaGhaNFhHNWlHdkVubjRfclpTWHNjVkdKNFFXS2pOOEJSTUpBOHFlcVQyRTByWGo1bXdnckpXSEMxajVUelc0QUg4TTRqbGRqS09xYVhkcmFvc0NBaEpFR3VtZWFvaEFISTJTNVp2eGd0aWxyWlZmSENkdmdSZ0VucVdvdWE5UVFHd1RsaHlTVG11MnJqOUZ2bzJ3SFBPTWFCSG1KcUtqRXNGcTNRWllRbG05V1FDZDM0QUhqS21TYmNOSlBobmllSGhKX2tnaDU1eEJtRElJaXVucDhYWXY1ampZaDJqbE5OcFVkbnVOam5fX091UWFOMHpxUDZndmtnM004WWFhdnhYaUo3ZFFGOUc4VVIwUFZoOEVENEs3Q3RSNWF3UEdlUnEwUXE0ZjN5MzM5UXM2bS1Vdk1pR2xKVldETld6UGw0Nl9id21DNFZ5dy05aHJQS0E4MnhYcGJiR21LZkRTMlhwQ2JxSHA1YktMTUxWaTdFUWNPTXB0blNlWHRxOG5EMS1wSGlPWkw1anFGNmh0SGpSdDhDSi1tdjdrcm5SOXk3SnBYb0gwVU9JbUtmTFAzM2tvQUtDalgyaDVsbmJnZXJMeHVwX0dqSUFGV1M0b2VCR0ZqdTBsdkZkM2YzMThY	client	f021ec12-3785-4503-9045-e2b7e144f760	2025-11-03 21:45:00.519728+00	2026-11-03 21:45:00.519729+00	\N	\N	2025-11-03 21:45:00.543273+00
a2cbbc69-40c0-4801-902a-10a95d02143e	e7b6c38b-2845-4f28-b1b3-c86e90c4788f	Z0FBQUFBQnBDYTBNNldOVXFIV3piQzI3Sl9pMTk5S0RibjVydVdIZ2tBZzRST2x3UEwwVHhjTWlpaHplZHFZVnp6aGNBWmJfR1ppREN6cmwtcVhkRVBGSGpJRzVBYUY4eVBGS2tDNHhKa1BHcnpkTXhHR19hRFNKaUV5TmE3WFZ6YmRoWXlyQWtzQ1B2Q1hxNmJINGFaOEdUamNwZ0dGQzBwR29CQWMteFhoTnlJUzlfcE9xSWlSQXJhcE9hMHBHWUczc2Eta1IxLWNydG9CSkotU015MHY5V3p4U09NV2MtRjJ5Yk9fSml5a1VsNXFVMlZUTXJmeVNJbmx5X1gyNTM2TU1teE00cDVuMFROeU43N01tVzZYTkZ1R253WHZ4NUJRTC1reVYxMzR2aGRQcGVGME1ESG0wQlZoMms0SURnWl8tSXgtbV9qenpmQWFUcF8tWlFZaDBveEEycmp3TFdURG9oaThfSnhINzFkclBiMjREcmR0LXdZQlZaaFlKTlBXZzJObmY0TDVreV9QYW5udjNUR3ZxcF84eHpMY3hrYXk0Z1owWVpCR1Q4M3ZMcFlEV0xIbmp3SUJrcVFRcXlUd2lONFhLeTVPcXo2dEdDdHJVc0hZVlNyeG5TQkthckJYdENkVWVpOUhLVWUySWFFUWp1dVVaWFE2cE1IblJPMmF2bzZHbXJLei1tZF9zdXRLVmVLcmprZGRJTlNFV0JDa2Vka3Q5amNoODVTRUJNR1lGanpQTmxncTVvekxtSE1DLVZ5QXZHUk02ZE1iZnR4RFJGS09lYnY4ZFc5X0NlUWRoQ1ZnYWdEbHRJbUpvamJGOGNJQjlNdmdvUllTZ2ZmaWxmeUo0OERpWlBkTDNhZVdwYzdGbk5nWWYtU0VCNE9wb0NqTVY0Mm5IbEdRcUtTdW1fM2hSSzdWZkt2TTFvQ1kxbGdtaVpaSEhkNGlmWEJoSVVmWGQ1RGdJQ0cwa1ZsU3ZBMVJoLUt4c0VQelJsU29yS2xzSGQtZ1J5cFdoaUNhbzdselhYZHN5RzM4emdsLTVWZHB2b3pCZDZQdVJjWFdkdTM1WkhlRGlRMWExQm5ZdjlaaGxhbi1zTWgtWFZjQ0ZsN1llSE9zcG5NNEFxdFZiQ0dlWVdZeFR3WHhvQWtWeXNKSzZDMWN3Tmx3X1dpTEhmaHlvN05vVkVGbURmZ0c2cFplclVGRmZFbExHcTRVWFl4RV9xTnkyVl81Um9ueEUyRUl6YjJWWE1ybWRuRER2TTZ4Nm05ZnByZUZfYXgzZTZHVGFLN3FyMTJuZlc1T0gxUlZnY0N0MHZWaGFlQ2xLc3ZSbjIzQm9kVEhwcWdNMmxhS2RaTWxMajBKVXpzUkFIUTN4UmRxMHlmNk1DdkxZRFBQUER0UVZhdVlvc2NldzkyeFBULTNkc1hqVmduNTY4d0l3QjgwN1VxU1c2LWpnM1ZaQ3FQS2ZfaWdyd0VCc0lOc2FHalhFZ0FLbFpMMnBJNTlRNzBGMERVc1ZfMng2WUtLMk1KTWJ2Y1JYQUNUTkVMZWVLM2pSQjFqSWpRSWI1WDFjRUVSbzJjVmpsOWhtWk9hemI4bXlYbzByUktWVnQtcmpuNkJwSUVBRFVDMGUtVzAzMWFOQ0ZSX05TUWJwaWVPZjhWUmxjOHpWdHFHcXluM0piMW44OXJVdk0yRDVQczg0a2poSV9fZUlhQkRycXlOalkyTHRkbnVRajY2clVqdnc5N3dialRSdzVVa3pPcmFVMjJKS1Vkamtqdkh4MEFkVTVQT2JCQ2NZcWNTNTRPdXJxR1FpNHZOY241V1gzV0VCUFZoM2JlbEhwb2dqMlppSEdleHZGSXBySFdOZ0wyT1ptYUdsVUdYdnlZckpkczRYM3loVGh5S1VQNjh0U1F4OWpZS0VjNFhJcXhhSzd5SDg4WUlnY0JfZUtuM2tiS1VydXdGNTQ0RV9FTVFlemFELWhYZG5sLXRsbExqN0JiNldTc2lNS0dxdVl5SXFHZUxOaVNMZm43QmlTYzg3dnp4QnN1N29lS0NHd09GamR6bVpWQmtzdjNwTlczQ0x5RDc3Yk9FVzJHTHFYN0ZPNlYtNWxkSmQyYUN2YWpTVFNjaWFycFNIeUhSR3hsVjRPNzVYS2NzUXhiQTh5d1ZHc1hmWjVkNlZ3V01GXzJvNGVNS1pfU2JFT3FPdmwwbjMza3hRMHJiMUFsYldJVU5GRU5KdWstTVFnZlN0SmhIYU42SUJQS3pLOENTT0cxNDZWck1jTHQ2WHBWcUVUZ1YzekhUYk1PVXYyaUI0VHduclZyZE96UjJhbVMyd2oxVTRMRkpFZk1TQ2dEN2pSaDcyTFZTM19xZW1VTE92djY0aV9YQ2pWSGpXX2x6XzV4NUU5QlJlekh0M0lWazdpd0x3WTk1Wjk3Rm10WGZmVmk4X0E1UEw4c1Jna0lMd3o2bDdyR25RdXg3UzdYcWFsdEtiSWtvanFVS2J1dWdYNkpOUUJ2c09XUWtGZFprb0NBPT0=	Z0FBQUFBQnBDYTBNMkdxTmcwLXZYcldYaVJ4d1NuTWVYMDFXMkZrcEpURDJqSW9ieElKazNVRzJPVGxIT3pJYUN0R3lBTG1NUXdndmprckp6TktaanpyeXNjWGo5bGc1cnpnODFpd3cxUVRQeFRvcWRxZk1pWjNGbGxVQkRnWF93X1pYOVFDbHNoZU9jZlFzWTNvMEY1UE5xMHZWMHVPNndxc1V0dlVFbjhxMWt3eUFzYTFYc1gyQVNnOEcxeGo2NGZ6YUlFVGdWak1PN3hhZDIyZFMwelJjdktuSnZDaE5IdDhYX0RtUlJfcHRwblJCOFhxMnJGWnd4OEdfMnRaMjN4QjNPa3VSX01WUlRVOFZtWGtUcUhBdmxSdDBaQUFickxWQXlzWksxRko4Z2t3cmowcnM4SzhtenNZdldxemJITGVsQmpBanJtS0ZzZzhyWTQtV1BJSGxYSHJEUGR2bGNtRDBSaTU4T2ExMEp4d0NDN0RjVjNWemRQVDZCdDdSQWVwYV9xb2JfZHN4V3pQbGR5Y3FDWnFZWWtVQ2k0bktFanZoeXFQMlRQaDhzUndyRmswVXg3YkJFanhJWFFXRkZLUVA0YVA5cVBSM3RJWm4wV1E2aVNnN2FYcV9odEppREQxRjRuLXEyY3dOYjUyckdqS0RVcWZObHdDbHp4NzQ4TG9oaFAtbGstb2VYMV9rYUhidXJFWU0wNmF3bUd1MVdQWC1VTUd0bnZqaUx0VHlVbDhaSVc3UUpkczVGZ3JLODlJenpBZnZOUU1TSjQzdlRFaTJvb0tWVHVnVldzNjBJTW5kbWdyaDNvOUtoMnl3QkgyWDRoVVotZDc5dW96dUxSMXh1OUdRTW9mNk15c2l3U2xEVklvTGpIMV9Fb2hEVDhfWHZBMmM2VThESmctTnRSbHRQbU4tYV9CdEdZTXQ0RTBHbVFfMmJtcXBhSEc0NzVMd2lZNXJwYmYxX0VfSzc2NC1QbHd4bE9TNmtDT0UwdVVDLTZJMHJkOXJoTDNJN3gxVWYyZjlRN1RlZFdnV09tRmV4QkExZGFKWGYzY292UVZJTU1yd2pid015azFHQkdSaWhWYVgzT2R0SzFnYU9zSFpjZUMzYlMyWjY3eVpaY2VzcGNlUHhIOE1tanJFRWR3QWF6OFRWVnlQRmh0ZVNyN1RWa0hlQjBDLS1zaFoyMnk0VUFJb2lfQmd1UzVRZDVLdjVEc09ITEZlQXJlZlJSNmVoZUk0dGlmaHNHWE9jTkVVaTI4OU4zMzNGUUgtTFBEUWNNVG9xV291VGYzNTdUZ0JKTlZVbFM3VGhVSzFlSjVmX0ZfTHRpOEg5NFNwSVJyLVRZeERjMUhoRFVHRmhWbXdRSzlUblg5QTFibGQ3R25NZkhTb1IzRVNRZFFZbllQem9SLXdDZjVfMGtYb3E1UThaV0dhQnhJb3JHeFlrRFlvNmYxNUdkVTRWaFVDZXEtcWk0THBTTkdzV2VldllLOWt4akUxekNydjhSX3hzOTMyeUZSUlVpRnNCNVdBeENyX09nYnBzNnNaTVVQcjk4aE9qQUVJejF3ZURlbzFqMlVQdHJKUHhvbUxZb0I4UW5SWENmVmEwd0xMZXZXZFFEZURRbXc5dUJDaFBwQnNLNGFfUGhjZmcxdFV4a0lsOE1vV3B0dDBnOTdxVy1nX1E3Y0d6Ni1taUxPTU4wT0lERE55NllxaVNKaEZOeV9ZbjFqWXlXcVo5OFpMYzJoaDRaMGtyQTF2NVVva0RhOXFhMFFqQUtfeDNLZGNISWhrXzZvZklOYVA5dzFmVzc5RU9Id1dLZm9ETEk2S3p0eE42SjlFY2NhalVHcTBITFdrUkhyQmFIdHIzNDd0M2lpZV9SX3hTaE9YYVZZeWJQWFExU1dfSUVsOGZTdzFoRWJIM3NrUVB5MF9MbnJySVg2Ty1RMDgyTmFoN3FQeXFSWUhPeExDLXd5SGh3UU4xRzBqRVUtS2EtN2NvU245S2dQRUdXWlJuUzl5Qk5XSlFnTzMtM2VTdG8tTDRBZ21ZNE9JQWd6cW5IRTFPOGJsY0VFTmprekFMRnpIVzRGYnRHLXdJSzdiX1NNMDIwaW8zWHVCNndQS3E1Q2lhU2M2SFpmdU55UFcyM0Qtd2E0cVcxVmpsUVdzRy1xbTAycEw0ckVmNU12Q000YW81emU4SE9aWVpQUU43c3p5c1FtWXV4VUx3eHhtS2p5VWZHR1NRY1NXc2lTX1BKdUlha2h5dFo5aDRYYnU5Uk5Kdmh6M0VYZ2J1MDdETENnUWhaVGktUHc2RWpWRWZiSC1yYVg5QnZ4YnluLVFhekFUSGZWRFBFZHNjT1pOTmhiaGczbHo5RFVUd1o2eVNRV3o3SHlJUW53ZzRzMmxFYUNkWlRuQW90ZEg5TFphUHZpdDVuNXVJZUJsQVNZV0ktY09LTDU0VTU2VXlaLUVwd2p1d1pnN0ZwekVxWUxQSWp1WlFTc1RNYU5nWDZQaW5jb0lLM0F3TUZiSE43MDk2MW9LUlB1X0ZPalVmU0hVVTdvcUlPWWdldER6NS1ITmdad2dFejdHVTVkb18tVW5XdFRQczdBQnJrNmNsWXV2WEZwaVhYbW9EWU9PUldlczRBd1NHcXRsNC0tclZBMXRpcHQtMFJPcnRPbnMtckxOVGVNX2EteTM0OG1JS2FMTkRGakZZcXdtZ05HYzlmQ2VXMnpZQU1lanhRbTVFVTBKUFRLT1kxWE41NWw5bjBsUUwtZXc5UHNDT0l6OC05MDRjSk1RQkp3Y01vVklvbmF3aFJudnJrNmg0azJzTmJVQWdGM1FhYW5EQnlGbTJKa2htc1l2MmdGdU1FNTRPYVV1Ml9UZExldVNJaEdPQU96QUZfQVRXcld1UzVFUmxKci1UcHNKUHRqWkM2dWFxRHhac0lvc1ZRamI0dkdpLWZGZ25jQ21JUmRSaC1femRFbE5XWXNWXzdtbnJuZmhMaThnWHRSZ3M1bnBtTDNSTVpjNmwzdVNGNWdaNWxkTTJCNDBqUFJ4RGM3LVk2U05TSXNCYkl3R21kUFJ3LTdVcnhWUHdfOTkyaUQt	client	ef423911-4c48-4346-9f1f-99b0ba99c5ba	2025-11-03 23:36:44.897567+00	2026-11-03 23:36:44.897581+00	\N	\N	2025-11-03 23:36:44.92247+00
\.


--
-- Data for Name: device_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_data (id, device_id, "timestamp", data_type, value, quality) FROM stdin;
\.


--
-- Data for Name: device_encryption_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_encryption_keys (id, device_id, key_encrypted, key_hash, created_by, created_at, updated_at, is_active) FROM stdin;
065227ba-d1bf-437d-86a3-4169e3e9d2bc	e7b6c38b-2845-4f28-b1b3-c86e90c4788f	Z0FBQUFBQnBDYTVraEtjT3piR3BMVzdQUS10bEVhOVJfUHhMNmFMcDM2SFdfSlZCSUdhWGUzNm1ma2luQ2ljY2ZHeVFZc1FkZlhvcVpjUnlhdGRfeENtVzZpVmRkbHNncDNCUzl1N1lIajZxNVVZTVVDb2FxcFpyeU5pekRVdTMxdUxiUmFMb2c5OWU=	de105da8fab2dfdc16a5d2f993756271c88bb68a9f9a6c28c66d3130fa6e5101	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 23:42:28.661423+00	2025-11-03 23:42:28.661427+00	t
6040555f-2801-4443-a32a-510b07ce4e96	8697991c-4de3-4a5c-9961-ba73acfb61f4	Z0FBQUFBQnBDZWNkUy14X3pXb2JmTjI3ZU1ub3EzejNaQkI2eS1pME9DZnc1Ym9fdzZCMXdZM1dzV2liOFppbEVuYzRCUUFaY3dpb0tXa1c0b0RETEY5TV9ES2dPa0IwTEZIbnN4QTdCSnQzaDFkZFVkLUhac3loRlVBUzFPbFRCMllXaDF4VUx2QXY=	c9126d1fadde7775f17ca0345df4681abd31e73c4a1cd2b4a88d7bb958485221	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-04 03:44:29.967154+00	2025-11-04 03:44:29.967157+00	t
7b47a7f5-c97b-4ed4-9dde-d51c56e4ec87	01d5838b-f778-460d-a32c-11d5bb4816c1	Z0FBQUFBQnBDZkJJSG9XWEI1RFJJaTZSTUhaOHlZa3JISnZjRDVVSmdKMkhpQzRhNExUNTFQY2FYRjFhVlI0X2R4LUNRSzBGSU56R3Z3czZvTEJ3Vm5TeHYzNllHOEdWVTBJdEZENHp6OHl3c293b3F1anp4cWI2blRNcDRzN1Z3QWl6Rjl3d0c3Y08=	5a1299bfe6c58d29eb06ea35f604fa7a54f51eef3482f16ab79a79e36173da9a	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-04 04:23:36.65741+00	2025-11-04 04:23:36.657413+00	t
\.


--
-- Data for Name: device_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_logs (id, device_id, log_type, message, log_metadata, created_at) FROM stdin;
\.


--
-- Data for Name: device_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_metrics (id, device_id, metric_type, metrics, "timestamp") FROM stdin;
f3232629-448a-45eb-b982-b387ec2d3680	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.5}	2025-11-03 12:07:46.102481
7e223453-ae6a-4ae6-8e1d-07c3d5341d80	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.9}	2025-11-03 12:07:46.102578
01fc666b-7dea-4ac8-864a-40ddd703e338	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.4}	2025-11-03 12:07:46.102613
5c7ef92b-05c3-4593-a878-1af6b4a38485	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.9}	2025-11-03 13:46:17.119049
05369368-f979-4df9-9f03-feb1e8c28caa	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.5}	2025-11-03 13:46:17.119189
ec7df099-03d3-4e12-bb3c-6ffaa883d5a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.3}	2025-11-03 13:46:17.119238
5aecd049-04b0-42eb-86f7-539ccae480fa	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.6}	2025-11-03 13:48:59.506746
e0476937-ce61-4c44-81d0-535aa9e0bb9e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.2}	2025-11-03 13:48:59.506812
e0f6824e-be6f-4380-8f94-3c570a541d42	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.9}	2025-11-03 13:48:59.506837
d6464d11-42e7-4d55-919e-6a45eb5bec4a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30}	2025-11-03 13:49:19.390257
55079d63-0e7e-4b43-bfd1-e6ae0ad441c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.3}	2025-11-03 13:49:19.390338
c1f78ab9-ee0c-40a7-92f4-4c0ca59aa36b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.1}	2025-11-03 13:49:19.390364
40a65cb9-61be-4a26-a74f-e058b6782b72	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34}	2025-11-03 13:49:39.461737
86c9c531-0861-45b3-b322-02451c628349	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.2}	2025-11-03 13:49:39.461825
2879ca10-acb6-4be4-83ff-0a36bd6fed31	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.6}	2025-11-03 13:49:39.461862
28f8061a-0e10-4411-8b26-65204b13e4cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.1}	2025-11-03 13:50:19.601362
1c5c9018-4d90-464f-8bd0-d8d342758f36	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.8}	2025-11-03 13:50:19.601464
11a0561a-8566-431e-9b6a-113b96db484f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94}	2025-11-03 13:50:19.6015
a00fdcdf-d682-4c95-b8af-8072e163f1a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.3}	2025-11-03 13:50:39.78736
b50ceee2-eb34-4b52-950c-06a5f40404e8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.7}	2025-11-03 13:50:39.787449
eed5dfb4-40c8-4674-95b6-00b0e129bfe3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.1}	2025-11-03 13:50:39.78748
af1229d0-48f5-4397-85dc-6e8c2da6ea83	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-03 13:52:38.139825
160d83c1-c925-4a3d-8111-477673b90bac	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.2}	2025-11-03 13:52:38.139897
15fb44bf-4f18-454b-a9e1-ca2352a9c68f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.6}	2025-11-03 13:52:38.139919
3babcbfd-8b03-4049-a688-8b29129ce16a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.6}	2025-11-03 13:53:18.274346
e5b4f3da-3949-40ca-8a60-b6ae1a5b7706	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.3}	2025-11-03 13:53:18.274428
a7f0dbb0-7eca-4613-a479-239c07eba60b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.1}	2025-11-03 13:53:18.27445
1feba1fa-b049-4d8a-865b-09fb59727dd9	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.9}	2025-11-03 13:53:28.31104
3d8c3b7e-198d-4f0a-b7e0-b4a5c6a92720	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.3}	2025-11-03 13:53:28.311119
f55b879e-d4b7-4379-a090-c0d67aaadc50	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.1}	2025-11-03 13:53:28.311158
cf837e8c-d17c-4aff-b210-d14de8a0ebe2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.2}	2025-11-03 13:54:08.451431
f8dedd07-74c0-40aa-8956-8414f312f420	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.7}	2025-11-03 13:54:08.451497
6f7dc829-8ebc-4966-aefc-de59eeaf3eb5	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101}	2025-11-03 13:54:08.451532
880f5040-d17a-45b0-b174-b9e9659f2da9	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.8}	2025-11-03 13:54:59.351946
bf6d6639-63db-4fcb-a981-35f7b205cbb1	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.4}	2025-11-03 13:54:59.352086
808dee59-c021-405b-81bf-004edec6c0a3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.9}	2025-11-03 13:54:59.352138
a2b1bf7c-c68d-45c5-8dcf-6638b9f3f3c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.1}	2025-11-03 13:55:38.952588
a8a2b971-7931-434a-b13a-aa1e62b40cb4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69}	2025-11-03 13:55:38.952678
f3cfd3b5-071c-4559-be17-f279a81962ab	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.2}	2025-11-03 13:55:38.952706
bd4bb9ca-1d88-43fa-8ac7-fe87a0663eeb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.2}	2025-11-03 13:56:19.022474
cdbc71bf-e74e-43b8-9f0f-a26820fa9484	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.1}	2025-11-03 13:56:19.022565
55c18020-6d69-4d0c-b886-3bb78cf4bfaa	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.7}	2025-11-03 13:56:19.022588
84c28f4a-5b97-40bf-9712-6903e30ff70a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.4}	2025-11-03 13:56:29.17468
65c76894-752f-4b48-bb80-ea1a58b5ed9e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.3}	2025-11-03 13:56:29.174778
16dff153-4eda-407e-838d-de1f8c65ba60	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.2}	2025-11-03 13:56:29.174813
1f8d1a4e-cb71-4d56-853e-9d8428006e91	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.6}	2025-11-03 13:57:39.509183
9c997a66-bb7d-43f8-8080-f56a4cb92723	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.6}	2025-11-03 13:57:39.509274
90d4f1ce-4a7e-4456-99ca-eb7bb49fc163	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.6}	2025-11-03 13:57:39.509311
54f749a8-c9ee-4239-bcd2-5f473d6388cc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.9}	2025-11-03 13:57:59.579423
a39523bd-cbe2-46c6-9161-1f76be779b4f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.2}	2025-11-03 13:57:59.579533
ab899ead-ecde-41f4-9566-99599f8f7ce7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.2}	2025-11-03 13:57:59.579569
459a48b7-37be-41ab-a980-d56628230770	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.1}	2025-11-03 13:58:49.767386
d7c44bc6-2c57-4a8f-97e3-5b28013b51a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.8}	2025-11-03 13:58:49.767497
a238ec6f-1be3-4220-b063-aeb5403c57a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.5}	2025-11-03 13:58:49.767537
184cee83-6d7a-4af7-a1d6-ecf7b68a51d2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.4}	2025-11-03 13:59:09.838286
4a5867af-460f-46c1-af8d-5b631e6a91c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.6}	2025-11-03 13:59:09.838375
74f42f9d-730d-4841-80cf-06aa94390850	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.6}	2025-11-03 13:59:09.838409
32db10bf-f891-4fee-8f1c-447c05387705	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.1}	2025-11-03 13:59:29.893617
e0c134d6-7b3e-491c-bd74-75b346ddd2c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.3}	2025-11-03 13:59:29.893697
7febe0d5-4a8f-4f11-a895-bfe0cfb32e26	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.3}	2025-11-03 13:59:29.893731
d4146666-bfb9-4074-8586-c7525f1ec5f2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.3}	2025-11-03 14:00:20.066469
4ee715e0-a123-4360-b7db-7ef7ef0c66f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.6}	2025-11-03 14:00:20.066561
4b2fb84b-0020-406e-b214-6077e1d443da	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.9}	2025-11-03 14:00:20.066597
9c2faf84-73aa-4643-a9d9-a5a5af2c7719	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.4}	2025-11-03 14:00:40.134733
af2c7a1f-ad09-4ce1-a962-327b6ca3238d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.9}	2025-11-03 14:00:40.13481
b328bca5-3949-45f0-a6df-dafc8b72ab92	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.1}	2025-11-03 14:00:40.134842
5fb7583f-7fce-457b-a04d-0151f0ccf07d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.3}	2025-11-03 14:01:00.204558
a6046983-8974-4aec-9a74-279af9eaf5c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.7}	2025-11-03 14:01:00.20463
263174fc-41ee-4d95-8f1d-c783958ce149	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.9}	2025-11-03 14:01:00.204654
0dd9382c-dfb0-4047-891d-1d718e1d71c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.5}	2025-11-03 14:01:50.378654
1c1fa9cb-f605-45da-9947-2aac3e2148c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.6}	2025-11-03 14:01:50.378724
4ca2b6fb-9f36-49ed-b177-7eb435af2afd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.8}	2025-11-03 14:01:50.378748
6e1e791c-f3a8-4466-9d46-993c275122ba	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.3}	2025-11-03 14:02:10.465801
6771bd82-b2d9-4cef-982d-1dee09089d0a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.4}	2025-11-03 14:02:10.465943
3f583a31-8a1c-40d9-a28a-256f64464c4f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.2}	2025-11-03 14:02:10.46598
494b695e-471b-4d1d-9f0f-03044965472d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-03 14:02:30.527752
b7b0bc19-5dcf-4dcb-b6a2-ace446ec5e4b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.6}	2025-11-03 14:02:30.527908
de651c7e-4682-4356-abcb-279a6d8d29dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.5}	2025-11-03 14:02:30.527941
06facb75-6afa-4fce-9bb2-13bf9734e228	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.5}	2025-11-03 14:03:20.705039
7d350c79-6114-419d-b5e4-fb33434dd5de	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.4}	2025-11-03 14:03:20.705197
7594320b-b6dc-44ab-aee9-2897bd278f58	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.3}	2025-11-03 14:03:20.705238
e4228b48-af93-4b3d-9483-643519fca8ab	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.6}	2025-11-03 14:03:40.775258
21947a41-17a2-4305-b9bd-69dcb1e13d1b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.1}	2025-11-03 14:03:40.775344
09e2aacf-b862-42ef-a0bf-b78912d46d9a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.8}	2025-11-03 14:03:40.775368
042aacda-96e0-4551-a668-7caf1ba82c6c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.1}	2025-11-03 14:04:00.844265
7da0cec0-a50e-426b-a6f7-e269635a498a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.7}	2025-11-03 14:04:00.844378
35aeb9dd-9742-4656-b6e4-2ae9c88c67b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.4}	2025-11-03 14:04:00.844409
a7bffaa2-b933-4a8a-b5df-d59e57d29a70	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.6}	2025-11-03 14:04:51.127955
ccd41399-090d-4db6-a6d8-e9660cbdb36a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.5}	2025-11-03 14:04:51.128042
6d7952a3-4bb1-4a48-b827-4875fa2abd9f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.7}	2025-11-03 14:04:51.128074
9c3c2994-4dfb-494f-b841-d52f4a3b2d52	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.5}	2025-11-03 14:05:11.200044
f36e409d-0a9f-4fee-8728-1d59d45f22d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.6}	2025-11-03 14:05:11.200119
5128421a-71db-421e-afef-42af900c16c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.9}	2025-11-03 14:05:11.200159
e861334f-6e28-4ad3-878a-7674aa720ea5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.3}	2025-11-03 14:05:31.373974
c2501120-3449-4bb8-bd50-805d25ad7f88	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.7}	2025-11-03 14:05:31.374048
afa279d9-9d2a-4266-ae9e-1f669cb6da81	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.9}	2025-11-03 14:05:31.374072
42598205-31b8-47e6-839b-e7a227776f37	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.8}	2025-11-03 14:06:21.850467
8cea43a0-ddd0-4e4b-b326-8064dc4991c9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.4}	2025-11-03 14:06:21.850538
f1a27136-4807-410f-bd6e-6684ce73b8fe	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.4}	2025-11-03 14:06:21.850561
3fdc876e-721a-4b5e-b6b3-6652d4d4b671	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.2}	2025-11-03 14:06:41.893237
f0e927d3-ecb9-471d-ab41-a733bf6d9420	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.6}	2025-11-03 14:06:41.893334
1f994662-2c92-45e8-ba17-5f30fec2bf95	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98}	2025-11-03 14:06:41.893361
6631aaed-646b-41ad-9128-0af4b652e418	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.2}	2025-11-03 14:07:02.106056
c7ed0221-0b9f-463c-9133-c33ac460aee4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.2}	2025-11-03 14:07:02.106163
4c5cf4ed-1dc2-414d-b73e-41ad160826f2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.3}	2025-11-03 14:07:02.106203
9a9dd826-60f5-4020-950b-95a7d662760c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.3}	2025-11-03 14:07:52.385292
889bc4d8-4310-4a04-895e-01c0094f88f5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.6}	2025-11-03 14:07:52.385372
458f703a-605b-44fc-b986-c0c8df210259	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.6}	2025-11-03 14:07:52.385397
d9dfc84c-065b-493e-969c-93ef8dc94005	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.3}	2025-11-03 14:08:12.459098
b5b42ddb-64dd-4e9f-b968-51df6f898b29	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.5}	2025-11-03 14:08:12.459248
b2b91d2d-de69-4da2-afb0-8cc43aad1bf0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.7}	2025-11-03 14:08:12.459285
ab96ae1b-5954-4d42-afa9-9052cec31b55	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.3}	2025-11-03 14:08:32.527822
c1031704-1eae-405a-a300-eedbbaec1d6f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.7}	2025-11-03 14:08:32.52793
177561b8-7bf6-4d2a-bccd-a3aaa24052b7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.3}	2025-11-03 14:08:32.527966
6ee1c6d4-37b0-4fe9-a584-f676e728174c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.9}	2025-11-03 14:09:22.78676
aacab611-d78a-49ce-be4c-1cea0ac65305	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.2}	2025-11-03 14:09:22.786835
8bdf23b6-65f2-4561-83da-b64bd59a6e5c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.2}	2025-11-03 14:09:22.786867
19fba993-df5d-4197-afb6-8ca130e8877b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.2}	2025-11-03 14:09:42.752774
46043aa1-b86c-4229-bfda-0247a4c5c272	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.4}	2025-11-03 14:09:42.752848
79a220dc-1c07-42cd-8c29-974cf0b661be	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.7}	2025-11-03 14:09:42.75287
953a853c-b45d-4c0b-84e2-5df439f8c5de	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.5}	2025-11-03 14:10:02.931945
28383923-342d-4d61-9e86-afcbae7c1b58	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.9}	2025-11-03 14:10:02.932017
62a8701e-a2af-4d31-b16b-d522710af6dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94}	2025-11-03 14:10:02.932043
75f51c3f-aa15-4991-b473-74e2e97a711e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.5}	2025-11-04 11:22:24.813994
2260192b-9129-4e51-a88a-cb29568f48e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.0}	2025-11-04 11:22:24.814087
c66cc541-73ad-4c65-a5c2-06e1dc79616f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.5}	2025-11-04 11:22:42.441736
b2dc121b-bfef-408d-a34b-9d59c167a890	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.0}	2025-11-04 11:22:42.441809
c579a687-a0e4-43ad-a3f4-491ad870c609	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.4}	2025-11-04 12:11:05.566448
d193d26d-0a88-405b-b658-78a769abb6f5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.8}	2025-11-04 12:11:05.56661
8428c947-6938-443b-b796-d396275cd595	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:11:05.566657
e742763c-9a69-496e-9cbf-ceb519c11184	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.1}	2025-11-04 12:11:05.566695
ffde2948-7275-4ec6-a4e8-2d18756c8c78	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:05.566724
2ce18236-9c00-41a0-a3c0-a76a1009d55e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:05.566755
496b7da7-1899-40ea-ae6b-06ae24b68d67	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 111}	2025-11-04 12:11:05.566782
4e1f14ec-e496-4254-818b-29191a448a76	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.9}	2025-11-04 12:11:15.57763
c29701b5-69d0-4404-9443-b04f58a9faba	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.3}	2025-11-04 12:11:15.577754
74bb83c8-a21e-436b-be9c-4a2e5f1fc691	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:11:15.577781
06947a5f-ab17-4e10-a180-07b398515140	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.1}	2025-11-04 12:11:15.577803
39b3ec10-24d0-4526-8a52-99da544899ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:15.577824
86c43953-66e2-49eb-a59f-2e2757d79f2f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:15.577845
28ea3906-5b09-42e0-a8c1-7e132546c0a7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 121}	2025-11-04 12:11:15.577864
ce75ae23-5dcc-4429-842a-1be01f6c92ae	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.1}	2025-11-04 12:11:25.579917
7ef99d34-029e-489d-9d07-5c71706b8766	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.2}	2025-11-04 12:11:25.579999
cfd2d1bb-2a1f-44f5-9500-28306912ade7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:11:25.580034
2f8d9ec4-93f1-4521-aa59-43f3d34cb92c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102}	2025-11-04 12:11:25.580061
b6a1087f-ab7a-4c46-a413-4422c53138c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:25.580082
c9644fe7-c26f-46e4-b4da-2748020e9ae0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:25.580105
a8880c1b-5bfb-4951-a34e-d65ab5395da7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 131}	2025-11-04 12:11:25.580133
2b27b654-1354-433e-9ac8-b35e9c3f165b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.5}	2025-11-04 12:11:35.593529
18117193-2dfd-4176-af93-8f4a35d769b5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.3}	2025-11-04 12:11:35.593596
99e33aaf-466d-4eb2-943c-b8c04cb22037	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:11:35.593618
6c53aa5e-05df-4d67-9a07-9c0e4ae77fc8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.5}	2025-11-04 12:11:35.593635
695ed4bb-dd26-479e-95b5-c7da56c15b4c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:35.593651
2c583e39-c83a-463e-9278-bab6750510bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:35.593666
1afb56de-d87a-4fa2-a886-b0df3a83daae	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 141}	2025-11-04 12:11:35.59368
0463a5c5-c06e-427d-98f0-f5ecc1d44195	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-04 12:11:45.601628
ccd6094a-d603-4a57-b2d0-b8a814afb26c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.1}	2025-11-04 12:11:45.601733
b3cbaf4f-c990-44ec-89dd-3f80a9cec828	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:11:45.601761
77ebf90d-17ce-4eac-ab8d-1ccc12225c29	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102}	2025-11-04 12:11:45.601781
22bfb3fe-664e-4a8d-8abd-8fd981b375b9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:45.6018
98e559ee-087b-420e-a479-1226b027022c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:45.601819
ef67fed7-1ad1-42cc-83d5-eaea143e7cc9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 151}	2025-11-04 12:11:45.601845
d54fcb50-b473-4386-a144-657462c0d8e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.5}	2025-11-04 12:11:55.598048
c95c11d9-6f73-4a20-b768-460b523bc1ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.5}	2025-11-04 12:11:55.59812
df273554-886e-4125-b41d-0ecd1095e663	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:11:55.598152
e3ca980f-9feb-4769-a270-ba59d3ede195	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.3}	2025-11-04 12:11:55.598188
548d16f4-edf8-4463-bc20-ce34fbbbcd26	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:11:55.598212
bf07f58e-aea8-4e0f-9be2-4aeb7bce4f9a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:11:55.598235
20119929-9a9d-42f5-83d0-a674f0b2b816	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 161}	2025-11-04 12:11:55.598256
cfd2f0d1-91b7-4fbe-8d91-f6a79e0e8d0c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.9}	2025-11-04 12:12:05.618233
a1b31ab0-32f3-40ab-9450-ed3c69456c1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60}	2025-11-04 12:12:05.618293
bda02b25-e756-48c2-977d-0bdec12da13e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:12:05.618315
102ca6a7-8a92-4f32-a408-bccd188a2735	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.6}	2025-11-04 12:12:05.618331
e14ec7ef-7419-47b5-b1b6-e8639e5b611f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:05.618346
7869ad69-f77c-4dbc-8a96-e7b6979d35e7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:05.618362
7f68bbf9-ea5b-4513-96ce-ac6b726e8cf9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 171}	2025-11-04 12:12:05.618377
c677323a-8798-4760-955b-3d7b12399f91	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.3}	2025-11-04 12:12:15.625316
655cd889-dc0e-40e1-a887-bc698c8fd9b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.5}	2025-11-04 12:12:15.625385
ff7def15-c8d6-4343-a6d9-9e05a41820c0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:12:15.625407
63dc21cb-fdbf-4823-9292-ec2e2b22806a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.4}	2025-11-04 12:12:15.625422
6281c449-9dc6-4298-909d-300ec5affb9c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:15.625437
dce83cfb-b8fc-4e6a-96fb-0620fc813216	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:15.625452
7229074c-ad9d-4b87-beaf-87c601d24146	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 181}	2025-11-04 12:12:15.625469
10403f24-5e01-4712-ab00-bd59d7f8e884	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.3}	2025-11-04 12:12:25.634304
c4354cff-da8c-4937-a581-a42b8f20e685	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.1}	2025-11-04 12:12:25.634375
b14cf730-a56c-4911-b4ee-d4bd90a5d10a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:12:25.634399
f20988e7-b71f-42b8-b3fc-11d550c35cf9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.3}	2025-11-04 12:12:25.634419
c73088b1-3e66-4773-b525-9d0af17c2b41	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:25.634438
6f840d53-e688-4613-b1b9-f71a6bb58ceb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:25.634455
39a1d574-823f-4f65-9484-832cd25abd53	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 191}	2025-11-04 12:12:25.634474
fd0ddf17-0380-4ccf-848d-b143e793cc78	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.3}	2025-11-04 12:12:35.652959
bbde4553-4deb-407b-abab-ce10ed1d69c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63}	2025-11-04 12:12:35.653063
563abbc1-3c45-4042-9da8-e66a95d646a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:12:35.653086
ab87dda1-570f-430b-9bd7-5ea58efa8aba	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.8}	2025-11-04 12:12:35.653105
23fff5f1-ba21-41bd-89e3-74b4b2ed9d0d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:35.653123
0ed1850e-cc6d-406c-ac6a-39b7f9a74a10	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:35.653139
0a70967b-f2f2-41a2-8047-365d13d2a462	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 201}	2025-11-04 12:12:35.653157
614f9fdb-7832-4870-8689-f871d3175c7e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.1}	2025-11-04 12:12:45.649435
a04efacc-b993-4de1-bccb-24853ebbd60f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.8}	2025-11-04 12:12:45.649499
fb6e9c29-4fc3-4bf1-b3c3-dd67ed673ac0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:12:45.649523
826108d9-2751-4ce6-b666-87376a9ac438	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97}	2025-11-04 12:12:45.649542
f3ac99e0-d491-4405-a247-afd145377619	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:45.64956
4294c77c-0410-4bc5-b1c8-d738d2729c04	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:45.649578
d59f4bde-05a8-4245-8584-77502fb74a8a	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 211}	2025-11-04 12:12:45.649595
83cedc2b-a87c-467e-bb31-8eaee5e9a59f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.6}	2025-11-04 12:12:55.659731
d6f6d2e6-3776-4ba1-932a-7d82d3c4c967	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.9}	2025-11-04 12:12:55.659836
260630fe-4e8a-4682-896f-1ff395b7b6fa	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:12:55.65986
8215c4bd-407e-4759-951d-363d1a922c12	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.1}	2025-11-04 12:12:55.65988
fe0c0d97-01ff-4317-a3cc-b9a4c96086b1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:12:55.659899
578e3c7c-e2c6-419e-9a54-374b13e3f717	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:12:55.659916
25702e7e-c7fd-4be5-8a69-558d6ce1bdc3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 221}	2025-11-04 12:12:55.659933
2d2a063c-a0e4-46de-8c17-ab6368bb934f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.7}	2025-11-04 12:13:05.674736
8a3aef6f-1984-422a-8b5f-a0cfb3b700b3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.7}	2025-11-04 12:13:05.674833
2b4c27d3-20d6-4c38-840e-71b79220d309	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:13:05.674864
939a8f3c-6388-413c-bb95-99898420ae8d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.7}	2025-11-04 12:13:05.674884
13b14786-d37b-47d0-9a4b-6fee52c22a32	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:05.674901
70da81a9-fa3d-4419-937b-4a6a75187d47	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:05.674916
c49a970a-1be3-45c5-9e16-721d71e95650	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 231}	2025-11-04 12:13:05.674931
8f38f6fb-9e40-4a27-97fe-0d4bc2983256	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.8}	2025-11-04 12:13:15.673844
79b5a0c7-f5b6-430e-b15a-538d7754095c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.1}	2025-11-04 12:13:15.673954
8774df48-82c4-4773-946f-963efcc020e0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:13:15.673985
3e3d1e42-cf7f-4617-a516-7868ff6c0d5f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.5}	2025-11-04 12:13:15.674012
70f1b528-3a04-49d2-aba2-e69fc8a48b7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:15.67404
476bf9c4-e010-4979-b011-38d7c0b3c68b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:15.674066
cb280ed0-a015-48dc-8acd-375e613fe40d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 241}	2025-11-04 12:13:15.674091
4f9342ee-265a-4cd5-ae3c-351650e9f0e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.8}	2025-11-04 12:13:25.682855
5a01e26d-bde0-4656-b67c-f68f7cab1180	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.2}	2025-11-04 12:13:25.682972
b38c0156-eee5-44a3-833d-fa92de236bc2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:13:25.682993
e6cf5879-370e-4c70-a383-9156d7c2a212	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.7}	2025-11-04 12:13:25.683012
df1a9efc-a1f0-4c9f-ab43-9bfbabcb7428	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:25.683029
4ddc0f29-419b-433c-86d7-880b60daf8c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:25.683046
fb17b11a-4d3d-4591-a7cb-79b25272be74	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 251}	2025-11-04 12:13:25.683061
42f109c4-13dd-4a5c-8dff-89f63990926f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.3}	2025-11-04 12:13:35.696417
44f91baf-e58b-47ae-b846-a2974067200c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.9}	2025-11-04 12:13:35.696556
061c588f-c2cb-4429-8b4d-f2bbf38de05f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:13:35.696595
de4ca320-6b06-4c52-b97d-5e154c8ba158	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.1}	2025-11-04 12:13:35.696625
f85437fa-c912-4b25-aeba-718342265af1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:35.696654
4e6da266-42d0-4eb8-9618-f12a5ca022bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:35.696682
89c85164-0204-4b53-af83-a41f85f726a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 261}	2025-11-04 12:13:35.69671
e439635e-092d-4253-bb25-90cbb5c71977	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.3}	2025-11-04 12:13:45.694617
a0d05021-2075-4657-9cfc-2c1ba355b42c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.2}	2025-11-04 12:13:45.69469
6ed32de6-6287-41a7-8214-95ace3dbde03	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:13:45.694711
47371c88-80bb-4846-a086-05245890de59	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.4}	2025-11-04 12:13:45.694728
11531283-89b6-45b5-bd05-474bbe1bf956	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:45.694744
b1f2dbbd-cc05-47d2-9cb6-d2230ceeeb32	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:45.694759
d146df02-d92a-497b-8691-a2eea83dda6a	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 271}	2025-11-04 12:13:45.694774
146d4d9c-6af6-4e5c-be47-a7644a79c93c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.1}	2025-11-04 12:13:55.700357
ce90127e-0e54-4b99-a330-b6a99ab50dc2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74}	2025-11-04 12:13:55.70043
01e2f1a4-a13f-4b2d-ae32-a32a75c026e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:13:55.700452
310715e7-a9df-420f-a465-291150da3470	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.3}	2025-11-04 12:13:55.70047
0c59b753-e37f-41ce-8061-276e34715f56	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:13:55.700486
196d2d0f-0510-4876-b89f-1276fba756c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:13:55.700501
459f7f24-510c-4a39-8462-f4ba3223812f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 281}	2025-11-04 12:13:55.700516
5e12d86c-de09-4d76-a50e-ff4e620ba528	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.3}	2025-11-04 12:14:05.711293
67575b43-6879-4ec8-9498-d19369f4d8e6	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.7}	2025-11-04 12:14:05.711352
1415d705-5a6d-4d81-b861-ec626d6ed5ea	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:14:05.711372
1cf5e26b-1a76-4a39-9810-17f355e2ec88	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.5}	2025-11-04 12:14:05.711389
f6bd83c9-6f63-4eb4-8b93-4b14ddbc03cb	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:05.711404
0ef0fb17-6356-4246-a97e-ba69b14e4577	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:05.711418
973a97fc-360f-4f9b-8d0e-f661828355c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 291}	2025-11-04 12:14:05.711433
92c5216e-2503-4bc9-a428-ea29dd032ae8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.2}	2025-11-04 12:14:15.716883
f7cfdb4b-7280-433b-ab2c-a8a0ca1ee733	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.1}	2025-11-04 12:14:15.716944
877092e8-9fa9-4be1-85c4-e16204685af4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:14:15.716965
86a2e247-87b9-464e-9d23-635646e56322	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.2}	2025-11-04 12:14:15.716981
73453964-b624-4bf3-840f-3be12e6e8213	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:15.716996
fe042280-e7a0-4bf3-8a13-3c6802386d9c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:15.717011
f43f45ee-3b12-428a-874c-ba2d8e468f0f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 301}	2025-11-04 12:14:15.717025
b746112f-302a-4fda-87f8-6215c394ab4d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.7}	2025-11-04 12:14:25.727328
b0ab5be0-2a89-4b90-963a-0cc80a269e3c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.5}	2025-11-04 12:14:25.727391
30dbceb0-8d85-46d5-af26-d6e2309c33d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:14:25.727417
0000cb7d-ee11-4e37-aef7-6d7a6160a03f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.7}	2025-11-04 12:14:25.727437
75d8b28f-c954-4353-92f6-d215a164983a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:25.727458
b2085a5f-4a3a-484a-ab6c-b9c1f882e9af	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:25.727477
d586a475-3a46-4bf3-93b2-657fd67534b9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 311}	2025-11-04 12:14:25.727496
d4ff5703-5e4c-4e2d-93d6-09df1840e7d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-04 12:42:30.93043
f4188a28-23a8-49b0-ae2f-70c6efad65a6	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.2}	2025-11-04 12:42:30.930555
c966833b-476e-4a52-8fa2-981508470ac9	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:42:30.9306
c6a0a9ad-a4e0-487e-8c2b-abe5af9221e6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.4}	2025-11-04 12:42:30.930636
3bc37c7f-bc8f-4079-b4db-a062c5447f7c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:30.930673
3ce0bd11-4a27-479a-86ae-b07e0cb1c24e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:30.930702
e6554bf6-b022-4b87-b650-6f0ab64026fc	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1996}	2025-11-04 12:42:30.930731
e6df7a00-2120-4cea-80c0-28821c146fed	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.7}	2025-11-04 12:42:40.985279
685b9efc-3d91-4257-a2fa-bcfb3d700962	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.9}	2025-11-04 12:42:40.985413
ac85afae-f3c5-4d2f-a55d-1e53ba10bc1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:42:40.985446
f0a46c43-fc82-4b64-ad67-36f8fadead6c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.8}	2025-11-04 12:42:40.985476
82364947-dbea-40ee-a0fb-25cfbd19602b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:40.985501
1f09df23-bee3-492a-9799-6f60539dbba7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:40.985525
7226af6f-da98-418e-901d-142bc50e84b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2006}	2025-11-04 12:42:40.985549
d8f4b0ab-6e9c-49f1-bb09-db20937adff1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.3}	2025-11-04 12:42:51.045512
d37b609d-7135-44ae-93d3-92554ff8d729	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.2}	2025-11-04 12:42:51.045577
4e4518d6-3a5c-4816-9d3d-e1c249406f39	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:42:51.045598
771240e2-ec0a-404c-91e1-42eb5faf0833	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.2}	2025-11-04 12:42:51.045616
17f265ce-e6b5-4b4e-ac58-b64b2ea909ea	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:51.045633
f816a3dd-4736-48fe-bfbf-80212c58d389	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:51.045648
5eda11d7-5b07-41e2-a56b-2b0102271593	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2016}	2025-11-04 12:42:51.045663
82a1ca5c-51c5-44a9-9242-e168862c5e38	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.4}	2025-11-04 12:43:51.301401
ce300e47-1a4a-445f-9e5a-061b06acd22f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.9}	2025-11-04 12:43:51.301474
7c468439-3560-4b90-958c-a471ddabc1be	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:43:51.3015
fdc329e6-11ec-49bd-98e1-1fa2d6f0e6a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.9}	2025-11-04 12:43:51.30152
c59855cf-5f19-4ef0-bc18-2bf2fa4fd405	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:51.301535
33ebe202-adb9-40fb-9fe0-f873356ec26f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:51.301551
72dab67b-4073-44b4-bf17-bac971961076	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2076}	2025-11-04 12:43:51.301565
16431038-c91a-4b33-8d70-9c8a55ec5b83	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.2}	2025-11-04 12:44:31.429325
c9ea9ee2-c9da-45e4-892b-134bd1b28b64	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.4}	2025-11-04 12:44:31.429391
e592e4da-c4f9-429e-bd16-1f2ebd918e0d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:44:31.429414
c7c1fcd1-bf92-4967-a026-03c0ba521a36	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.4}	2025-11-04 12:44:31.429431
0a0224fa-0009-4335-bb0d-0b6f4830dcbe	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:44:31.429447
c144fa64-4678-4ef9-8205-67144cacbf18	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:44:31.429462
070b7f19-9386-474c-b82d-b7816a5bf2af	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2117}	2025-11-04 12:44:31.429477
dc20f2d6-6c4d-4172-ae0c-b94fff96d1a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:28:09.56683
422b75f1-7e44-46c9-a0e6-2235614c8b3f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 856}	2025-11-07 03:28:09.566848
38e70916-3295-437f-9518-27ebdd80cfae	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.2}	2025-11-04 12:14:35.741475
9bb6bdd0-5c58-46db-aea5-53d3b501bbe5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78.7}	2025-11-04 12:14:35.741538
5cbfe218-b797-4650-b6d6-dd496726411e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:14:35.741559
ad78a11b-d93c-49d6-8e70-25a585776154	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.2}	2025-11-04 12:14:35.741576
950d9b71-9713-43a6-9496-59f5e18cded8	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:35.741591
45f529b9-9b3e-440e-8274-ee08e69273f6	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:35.741607
d74d1a43-111d-4326-b716-6d903be5c074	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 321}	2025-11-04 12:14:35.741621
51d49298-b1f5-4079-83ca-45bbf3c9a8ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28}	2025-11-04 12:14:45.741229
28f04b40-2bb5-4646-907e-5890fa22a698	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.5}	2025-11-04 12:14:45.741286
2576c201-4256-4a66-be79-0884222b0040	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:14:45.741309
c95ab6ac-dedb-4d77-80af-1a58a3491550	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.1}	2025-11-04 12:14:45.741327
b4e013d5-c470-4139-a2e4-d0c6434ce6e9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:45.741344
c3ae51ed-560e-423a-a103-fede02295a99	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:45.74136
ff936f2e-7f73-4c5e-8436-89b35369aa30	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 331}	2025-11-04 12:14:45.741374
a679bcf9-ab4d-4810-af28-e998131ca53d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.2}	2025-11-04 12:14:55.747216
0345851e-e5f1-4a4b-b676-29514a318145	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.7}	2025-11-04 12:14:55.747279
afab75e7-7604-45d0-8294-49c64dc0db43	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:14:55.747302
7937da7e-d85c-423f-8a93-74f1f855a370	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.4}	2025-11-04 12:14:55.747321
6867c961-8825-41e2-ae2d-2df175549e3b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:14:55.747337
327490f9-6ce1-4caf-b1b2-6ab16cb3fada	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:14:55.747353
f4bd6b3c-cc4b-4730-b3eb-01e22f4fb782	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 341}	2025-11-04 12:14:55.747369
dba0d380-7a50-4ddf-a9ac-e6e7f6885b76	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.9}	2025-11-04 12:43:01.061355
b0943858-3949-44a7-b9d2-31859cae271e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.4}	2025-11-04 12:43:01.061421
6d6fa5f0-9b8f-4ba7-acb2-764b867fb671	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:43:01.061468
63995bee-ded6-4117-8d52-fa8e98eab01e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.2}	2025-11-04 12:43:01.061509
c8e52e2a-9161-4033-be64-10456ed874fd	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:01.061545
cb28a5ff-08d5-481a-90a7-70483f1a3e3d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:01.06158
f2d0ebfa-bd77-4a72-a2d5-11e75515b0f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2026}	2025-11-04 12:43:01.061615
8b4907bf-f174-4d05-9e69-5bd0e36f9222	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.4}	2025-11-04 12:43:11.118741
c5822fde-3692-4177-855d-10b1718b2335	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.3}	2025-11-04 12:43:11.118802
d4e82c44-04be-494d-a4cb-39c16174a85d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:43:11.118823
df62acff-5d19-4aed-8855-247ddc1e0f8b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.9}	2025-11-04 12:43:11.118844
8ae374ea-020c-4c96-aa95-1e02d3a558c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:11.118868
a3a1ccd5-98c2-4384-bf24-0b7c5cbd028e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:11.11889
910bb3c2-8791-4ed1-bcb0-987d3ce87877	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2036}	2025-11-04 12:43:11.118914
b70ad0e2-7935-4693-92d8-ad07fcc603ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.1}	2025-11-04 12:43:21.17393
d67117ad-e515-4328-9f63-9e8601c29c00	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64}	2025-11-04 12:43:21.174016
44ccaa75-da5c-4947-94e4-9535d254dad6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:43:21.17404
d430ece3-ef8c-4654-a97c-a4f48bb738c1	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.9}	2025-11-04 12:43:21.174058
3010c574-6e1f-4a59-a83c-8b5e08a72066	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:21.174075
97c12113-fd61-4763-bf0a-a3016c7b4cbe	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:21.17409
085b85fe-8c59-4b3a-af6a-dfecc63dbb29	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2046}	2025-11-04 12:43:21.174104
5debd454-26f0-46f6-aa65-471f187626cb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:43:41.239223
b3edb731-7dc7-46c1-94de-1740fddde898	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.8}	2025-11-04 12:43:41.239285
82f844cf-f89c-4c6b-9484-072bcc295ec7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:43:41.239307
2b9653aa-7557-43a1-a3ce-17f7c80aadd6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.3}	2025-11-04 12:43:41.239325
259a7362-7b6f-45b8-97e8-14e0b7eb7628	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:41.239341
00d1c381-e78e-4e56-bd35-15343f3c3215	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:41.239358
6acf63e1-145d-4c5d-93c6-3e2177905cfa	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2066}	2025-11-04 12:43:41.239375
737eddbb-8466-4128-bbb8-1f4ca74fafbb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.6}	2025-11-04 12:44:21.425075
0d1f0713-d76c-411c-814a-d7f17bdbc9d2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.6}	2025-11-04 12:44:21.425203
ecc6b4d7-75a5-4b86-8e1a-72af6fff8ea0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:44:21.425229
18477407-7607-4746-8cb4-fdb46303fd09	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.6}	2025-11-04 12:44:21.42525
4e6d9055-a3a6-4e7f-a4cc-dda40de99be4	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:44:21.425271
74e4d059-cabf-480d-9e4b-a4ba1a201cdb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:44:21.42529
ea741dbb-ad98-4556-904f-ff097c81470d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2107}	2025-11-04 12:44:21.42531
61ef529b-ff8a-4e54-acd9-2cf0cc449e12	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.8}	2025-11-04 12:15:05.79461
0a6c71b5-e335-41b1-b693-9f3d24df219e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.5}	2025-11-04 12:15:05.794722
3b3ec6f7-bf95-4eec-956f-619c394a725b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:15:05.794751
72b6f3a4-19f2-4125-b13c-1d962b88377c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.5}	2025-11-04 12:15:05.794775
cbafb056-6869-4b4d-a5a9-8d0c70043f7e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:05.794795
1bf09277-81ee-4c63-aac5-3e4ca89340ed	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:05.794815
0cca5b99-3b52-4b07-be66-adb9794827e0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 351}	2025-11-04 12:15:05.794836
14491a5c-690d-4de8-b761-ad198f4f975d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.6}	2025-11-04 12:15:15.757042
7dc97cfd-aa24-48b3-9b58-76aa2526df5d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.2}	2025-11-04 12:15:15.7571
b4a71321-a588-4dfd-956e-d5d415f1659d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:15:15.757123
3344288c-9de4-4f53-82d1-436c67840fb2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.7}	2025-11-04 12:15:15.757142
add92990-50e9-484c-8369-f97c4330d28b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:15.757167
72770b5d-4e2a-454f-b449-9ce6b45601d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:15.757204
d13e5420-fbab-4d96-a435-73224454f94b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 361}	2025-11-04 12:15:15.757226
4b009a61-b773-4f12-b0ba-03ef6ebfddda	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-04 12:15:25.765952
2a1d5750-2da8-432d-a9b2-8935f4d52a30	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61}	2025-11-04 12:15:25.766025
f317b0ea-bfc8-4e40-85ac-02fecb7bd575	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:15:25.76605
2084533c-c638-4224-9aa3-f32a19993010	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.8}	2025-11-04 12:15:25.76607
679b78c5-47a1-4d21-8825-5487b0992dbc	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:25.766089
0cdc6673-9b48-430c-9786-5e0321196551	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:25.766106
ae8366ad-4d6f-4406-9d39-0092626e8ae3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 371}	2025-11-04 12:15:25.766123
0695eed5-089a-4f31-94f8-71142d0194d1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.6}	2025-11-04 12:15:35.777066
292722e6-a5ed-46f1-9d2a-1bf66fa9d450	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.1}	2025-11-04 12:15:35.777161
40b3d4b5-3d1a-41ff-b36d-b65749906f2c	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:15:35.7772
1c59a247-9715-41e6-953f-2fb1bbf3dfb8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.5}	2025-11-04 12:15:35.777219
f93c0ef5-abf6-44fa-b5dd-d1d4fa92db30	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:35.777237
64ad5797-c7fa-4684-89ef-7141a1b24b66	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:35.777256
97ffe096-1c97-4d46-8bc7-c51483f8290c	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 381}	2025-11-04 12:15:35.777274
ce1e6313-0b16-41db-b95e-e2656f69c429	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.5}	2025-11-04 12:15:45.777566
a18f875b-d81a-487c-afa8-b83e7c6dc47f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.3}	2025-11-04 12:15:45.777628
2a3aa26a-dead-4fa1-8070-507753b12544	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:15:45.777656
0dfdd7dd-5d46-4b41-b470-2f8b4ca72eb5	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.2}	2025-11-04 12:15:45.777678
15c96b15-ee64-4723-86ca-332f85070f3f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:45.777699
769fd0c0-e5cc-4cad-a600-c1170b89b9c1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:45.777719
9018e9da-31c7-4c0f-83e7-0821d197d150	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 391}	2025-11-04 12:15:45.777738
1a1cde10-c7d9-4ff4-b7cb-54171416c993	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-04 12:15:55.79752
31cb09c8-d921-4b99-b33e-ecd9aeb55ebc	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.8}	2025-11-04 12:15:55.797709
d5e20bcb-0ec6-47b2-9343-0d849473fa19	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:15:55.797747
9f399fb5-723c-4ee4-b5c8-25bfdf393aed	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.6}	2025-11-04 12:15:55.797776
8bb8e0d0-9a23-46be-9a33-6286ed2c9c60	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:15:55.797802
992c3a46-ca52-4a6b-bc55-8627e77fcbf1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:15:55.797832
ec9bbd37-0965-4423-98b3-328a84e954fb	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 401}	2025-11-04 12:15:55.797862
d6db5408-1f2f-4572-9024-2f470e1632ed	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.6}	2025-11-04 12:16:05.797472
d4a5339c-85ee-4f8c-84a7-b1ddffbf8cf1	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.1}	2025-11-04 12:16:05.797536
c5a956a4-0c4e-4516-9ca8-37a6e8670da7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:16:05.797558
5f7edc72-805a-42b7-af6d-14892bb1dd5c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85}	2025-11-04 12:16:05.797577
f1ea9035-c493-4384-97f1-a73ed49a9b46	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:16:05.797594
bc3944e6-31b9-4a12-9555-02afc4ab184c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:16:05.79761
0fa6b4c1-67a1-4643-8622-fe8dee96ca9d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 411}	2025-11-04 12:16:05.797625
1d923785-57cf-4e30-8337-a3f91dcae7a6	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.4}	2025-11-04 12:16:15.898597
e35ece7a-806f-45bd-9cfc-92f3e7b0b197	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.6}	2025-11-04 12:16:15.898733
b8ca2301-0a2b-48ed-9052-1bf22eebd9f4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:16:15.898762
2f2c43ef-800c-4e9a-a4b9-2740ccd6f741	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101}	2025-11-04 12:16:15.898784
21fb1456-3809-4ef6-9a18-45bf7db2972e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:16:15.898807
d9aec851-fe0d-42a6-a524-7ab3d5620c63	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:16:15.898826
631de7e7-41b1-49ba-9559-0dd09b5ee049	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 421}	2025-11-04 12:16:15.898848
157f9623-3e99-4a5f-ba42-5c55c224a83e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.2}	2025-11-04 12:16:45.914903
be70d4af-9239-4b41-9f08-0309365eb77a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.6}	2025-11-04 12:16:45.915006
65b1c5d2-a2be-4a62-8151-7eaf90c81cc2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:16:45.915036
d3084855-5b4f-4d9d-82df-fc60516d2c50	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.3}	2025-11-04 12:16:45.915058
15a8494c-65d9-477d-a8b7-33d3a56e96d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:16:45.915078
d4c044e8-9491-4d82-a65f-00f283b2bf9e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:16:45.915098
6a9c7aac-b0a7-41f7-8a71-1a672ad35b15	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 451}	2025-11-04 12:16:45.915122
38a2e3ff-d90c-41be-a468-84b637b7d05c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.5}	2025-11-04 12:16:55.974296
db17cfd9-7199-43f1-ab96-1d686936fe4c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.8}	2025-11-04 12:16:55.974435
d44562c4-d86e-45f1-be17-9d307d5928ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:16:55.974467
bc9f7e0c-50c0-4d3a-82ce-0025d1ae41fa	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.8}	2025-11-04 12:16:55.974488
718b196a-044f-43b2-9d9f-e7fbb9a0fb5a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:16:55.974507
f4555292-9503-40da-86ad-836d073c9d6a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:16:55.974527
8b01e96b-b84c-4564-a1c4-6155dd131ffa	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 461}	2025-11-04 12:16:55.974568
2970a93a-6a13-42c3-a31d-7cede9ba413e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29}	2025-11-04 12:17:05.928905
8840b775-6be2-43fc-ba46-cc2eecbe609d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.5}	2025-11-04 12:17:05.929061
22b86393-5aa6-43bf-a388-f5b7aaaa6165	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:17:05.929097
01621b45-a501-451d-8f64-8cd35e563a3c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.1}	2025-11-04 12:17:05.929127
818df582-7962-4351-bc97-f358f5b197c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:05.929158
67427f42-8722-496f-9743-765414356084	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:05.929196
57adee68-8d4f-4c63-9f97-4abf450cdeba	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 471}	2025-11-04 12:17:05.929228
98864e56-ec6b-4081-a1ca-68f6d144d621	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.8}	2025-11-04 12:17:15.936411
7ef83195-9c15-497d-85e7-51a55d4a7d2c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.7}	2025-11-04 12:17:15.936523
11871b68-bdd2-4c71-a3f3-3d77826a2a14	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:17:15.936551
f150dbaa-15be-49aa-9deb-7ea56517cb02	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.5}	2025-11-04 12:17:15.936571
c2e84ce5-745e-4d06-a797-bbf525464405	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:15.936588
373e4bd2-d997-49d4-889b-43f079fbf5c9	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:15.936606
e3b02402-8ed2-414d-bddb-1e4d8b16e45b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 481}	2025-11-04 12:17:15.936624
0ff06426-0057-4a17-b8b5-8ecfa2134492	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.4}	2025-11-04 12:17:25.934305
b850ff6d-d476-4812-9d80-e1eafcb3a64b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.6}	2025-11-04 12:17:25.934414
4f90cf87-3c59-4055-8b48-099625b3f50d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:17:25.934436
fa995324-bfc1-45e1-87c4-d7837b52fee4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98}	2025-11-04 12:17:25.934454
245ddab8-fdb6-4bbf-93c7-d92dae512275	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:25.934472
ab3c53c6-ae52-4b62-8f70-fe577ac26083	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:25.934488
454b6700-60c8-419b-961b-9072b87589db	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 491}	2025-11-04 12:17:25.934503
e4e5b86b-8ca6-4d5f-9bae-5fc0ad94338e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.9}	2025-11-04 12:17:35.940453
6de8ea3b-df6a-4d32-b422-06d9d55832ba	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.4}	2025-11-04 12:17:35.940524
3079a313-9443-4962-89b2-f3a5d4dc6ec3	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:17:35.940553
e68e327f-41a0-481d-8a98-1b412f9bd170	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.5}	2025-11-04 12:17:35.940576
d4dd6b45-6fb0-4226-9d85-002ef013fa2e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:35.940596
e606064d-aee4-48ad-9622-41b9f9808ee8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:35.940618
fdd2509c-1782-4760-8021-e29c75b11515	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 501}	2025-11-04 12:17:35.94064
a2855624-770d-4069-8a8d-2a690a300d68	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.2}	2025-11-04 12:17:45.95352
b08d78c7-d45f-48f3-9ea1-4fd907bfeea1	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.2}	2025-11-04 12:17:45.953585
e7a1adfb-fcfb-4e81-9d3b-f6906d98988c	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:17:45.953607
1fe144c1-b40d-46f0-ac64-5984cebde52b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.5}	2025-11-04 12:17:45.953625
975c82db-8e47-4e02-805b-67ace2b374ea	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:45.95364
e31a5067-f0ea-4def-8662-9ee10ba55349	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:45.953655
66f5d366-53c5-4ec3-92f9-e548073e12d7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 511}	2025-11-04 12:17:45.95367
ad909781-336f-4e27-a20a-00d27ed1a543	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.6}	2025-11-04 12:17:55.946386
3d71469e-e9d3-4e5e-b862-2a461b8f545c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.6}	2025-11-04 12:17:55.946457
55053259-48b6-452c-ab2d-3a338561bc35	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:17:55.946485
d499d604-e9d8-4d8d-b0c1-ff5a0d80435e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.3}	2025-11-04 12:17:55.946506
a61b54b4-d379-4970-9a8f-72d1d5666331	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:17:55.946526
373bc404-553c-4769-a64b-9c70cc8e6de0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:17:55.946545
19b360f5-debb-4c6c-9b29-57a385d8fcc1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 521}	2025-11-04 12:17:55.946564
cf081050-ffd9-4900-8d81-147c21af3798	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-04 12:18:05.968984
6b17e3e8-c22f-4a10-a867-f7c04eeeb10c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.2}	2025-11-04 12:18:05.969066
337768ee-d9c1-407c-8e71-57d645da3a91	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:18:05.9691
6368b867-9d71-464f-aac5-f4d2c0e878aa	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94}	2025-11-04 12:18:05.96912
cd7c8e80-24ed-4521-a2b2-639611138763	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:05.969142
9da9002d-1934-4a61-851c-a399b0e4c809	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:05.969162
c419b60a-c04d-4381-a55e-8793c54ad29e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 531}	2025-11-04 12:18:05.969228
0e14a013-bda9-4839-b18e-cf62330e1b71	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.5}	2025-11-04 12:18:15.969311
55f0636c-242f-42dd-a319-10da30bf50ed	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.9}	2025-11-04 12:18:15.96942
532267e5-023c-4d25-81c6-0867ff403030	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:18:15.969452
f4da46cf-954f-44b6-a27e-fd3f657a14ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.4}	2025-11-04 12:18:15.969474
1757007e-5dc3-49bf-8029-67b1a179898e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:15.969494
7f967c13-a532-4802-8184-40d8d8bd377c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:15.969514
0bd7e942-9509-46d1-b4ed-6257411ebd97	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 541}	2025-11-04 12:18:15.969531
20338345-3820-402d-9164-7f1ae716c312	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-04 12:18:25.976393
f1bafcec-7cf8-405d-a53b-65cde6949d8c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.5}	2025-11-04 12:18:25.97649
15ebcfd1-c93a-4479-b6b8-dd9b9886d9ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:18:25.976527
f226739d-5a1c-4f9d-bf20-fd41e6b9fb1a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.3}	2025-11-04 12:18:25.976558
68ab7249-0c90-4f55-b831-6701c711705d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:25.976585
55373a90-965c-41de-b403-8e51737e7b1a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:25.976606
a91ba4ac-a515-4b4d-b685-df33bedccb90	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 551}	2025-11-04 12:18:25.976627
b73aae5d-895a-422c-8db8-cffb6892175a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.6}	2025-11-04 12:18:35.975619
62053b3f-5388-4d09-af64-50fe9ffa48b7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.9}	2025-11-04 12:18:35.975699
b67a71ac-a55b-4821-9c38-9adc4528d95e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:18:35.975734
d2f8341e-3e19-467e-85b0-70e6f0238df6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.6}	2025-11-04 12:18:35.975762
5c40eade-a79a-4517-b219-85c5a1768a32	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:35.975788
5006ff6d-fd94-4521-b30e-6f37077d911f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:35.975811
e08c1e8d-227c-4bfd-86bd-f9431fb62452	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 561}	2025-11-04 12:18:35.975834
072746ba-1fd3-430e-827b-24bbf70faa7b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33}	2025-11-04 12:18:45.978434
29d6c550-e61d-4cfd-a68f-cff9763400c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.7}	2025-11-04 12:18:45.978543
f823c869-2823-4980-bf96-380a32ae8470	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:18:45.978569
3f0193ce-b44c-4881-a860-d7d5244736d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.4}	2025-11-04 12:18:45.978589
f77b9f56-f8ae-4400-ae28-14d74f1a35b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:45.978608
749b7cd7-0e18-4b0d-a792-5d2005b7cabd	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:45.978627
762e943c-ae61-4782-a959-9faf62956ca5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 571}	2025-11-04 12:18:45.978647
16ca020e-2b7e-40f9-90a3-1598d9eb6503	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.8}	2025-11-04 12:18:55.990336
15564adf-81ee-4555-9a1f-210a51fef01c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.4}	2025-11-04 12:18:55.990413
5e867482-797c-4480-8d41-ff2dd4377d2d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:18:55.990435
22d54828-986c-461c-8313-5f7c5755b558	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.2}	2025-11-04 12:18:55.990454
444e3090-abd4-4468-80a6-966d875d87db	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:18:55.990471
016c98d7-e815-4ad0-bb9f-4d4936f1ac00	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:18:55.990485
07fc3f2d-f6f1-4477-ad79-d94dbeccdd3a	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 581}	2025-11-04 12:18:55.990499
3b73cd61-6c05-4047-af15-52ac19cbf3f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.5}	2025-11-04 12:19:05.99922
c01e223b-1e06-49ea-acaf-4a6af9f0193d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.1}	2025-11-04 12:19:05.999333
a66c3bba-c638-4e2e-8e2d-008d80b4871d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:19:05.999359
80da042a-0507-4654-9744-d2804731ac46	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.8}	2025-11-04 12:19:05.999379
4001d6d3-8f01-49c2-9835-1ada55632729	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:05.999399
d4225438-6f8f-4cb4-88ac-a6d8bc972ec3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:05.999417
027e7dae-b67b-40ad-bea5-850e82b68f10	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 591}	2025-11-04 12:19:05.999436
8733fe41-ff9a-4f51-bfec-c1908434af3f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.3}	2025-11-04 12:19:16.001112
f7069a6b-babd-4ca9-8b06-6db4cd9d3147	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.4}	2025-11-04 12:19:16.00119
a7fa344e-3f83-4ffd-9275-ed8050aabe08	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:19:16.001212
91d63ce4-f46d-404f-96af-785a537ff649	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104}	2025-11-04 12:19:16.001229
c69a28a1-904d-4401-9cac-723c157c7c1f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:16.001245
cfd327bb-b178-4a6c-accd-ef9257e86d4c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:16.001259
f86bb254-5c9f-48c8-b555-0dda7573a6a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 601}	2025-11-04 12:19:16.001274
5eee8838-2963-4186-8a02-82e033389992	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27}	2025-11-04 12:19:26.005322
a259f298-cbdf-4589-8520-998c86b63dae	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66}	2025-11-04 12:19:26.005422
dc4c9f0d-e128-465e-a647-0d6cfb0b92f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:19:26.005451
6ccdf980-953b-4dc2-9314-f2576c14da97	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.2}	2025-11-04 12:19:26.005475
1a850523-c520-4a82-a274-56b2c0cced78	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:26.005496
d6f9618f-d03a-42a0-9695-b434f260ad76	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:26.005517
66adb9df-7de2-4d15-b884-31c827da7e60	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 611}	2025-11-04 12:19:26.005537
0976cd52-4dbe-423f-86f6-ae15ff60e6f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.9}	2025-11-04 12:19:36.019032
68a23eeb-2784-4476-bd8f-d523d03b8361	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.8}	2025-11-04 12:19:36.019137
f6b80819-6028-4f39-aaf1-7fd24c633744	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:19:36.019161
6d9beeed-4238-4217-a2ce-2e026802cbbd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98}	2025-11-04 12:19:36.019194
d2ff9d30-30fc-4a51-9b28-897b8f08834c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:36.019215
2af0bb41-c9eb-4136-b6a7-1e63303614da	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:36.019233
42222efa-1572-49f5-b0ee-f5bc6bae12c6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 621}	2025-11-04 12:19:36.01925
a41311f4-f981-4b9d-b7ac-940ec8f87111	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.3}	2025-11-04 12:19:46.016941
64d5ed9a-ac54-4f25-b153-693f09bca289	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62}	2025-11-04 12:19:46.017083
7cfa71dc-4cb1-494c-a6d4-39d8cae49c1a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:19:46.017134
0e3c23c6-7a84-48eb-8607-3ec8119cc13f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.9}	2025-11-04 12:19:46.017163
2e6c49d0-db6c-4e87-9264-927ebe815582	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:46.017213
ab428cdd-d21f-4914-b96c-22befb09f58b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:46.017242
3c2e3013-8865-49c6-a5e0-d0c76bc44372	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 631}	2025-11-04 12:19:46.017266
963e4810-ba75-480f-a6cd-928bdd98fd6e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.7}	2025-11-04 12:19:56.022998
108a97fd-db6f-4bcf-b72f-cc57431e4f1a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.5}	2025-11-04 12:19:56.023082
8fc1c6cf-989b-454a-85eb-f82ddac30576	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:19:56.023104
e8cbe727-fded-4174-9d55-80a28f484dfb	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.3}	2025-11-04 12:19:56.023123
29cf4a81-a804-4197-b713-1a53097efe63	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:19:56.023138
49802087-c661-42b6-b2a9-d5006760e6c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:19:56.023152
2da69c43-0fed-4b98-ae4f-d1ab231aeb89	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 641}	2025-11-04 12:19:56.023167
2fb4fdbb-fc1c-4fec-878b-671c970e2b7e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.4}	2025-11-04 12:20:06.035945
2c262f2c-aeac-47cd-8314-970464bc910c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.8}	2025-11-04 12:20:06.036078
1f82862f-095d-4edf-bc9c-cce2ce2a5836	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:20:06.036112
0eeeffa6-c67c-43ad-9e88-9e0161c0232e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.6}	2025-11-04 12:20:06.036138
67da1b4b-b384-4938-b2e2-fcab063221a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:06.036164
b51a2f92-93c8-4f94-a583-329e468a25da	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:06.036209
92021b18-e035-4246-87f5-847c03b0896e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 651}	2025-11-04 12:20:06.036235
330e0c31-ff9b-4ccf-ae66-cda42980bba8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.4}	2025-11-04 12:20:16.033167
7df428a9-9304-4394-b64a-36a2f392fffa	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.4}	2025-11-04 12:20:16.033451
6ed8d414-3c9a-49d8-870e-757c0111ad6a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:20:16.03348
ea48eba3-f39b-4dfb-bf5c-344af4559218	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.7}	2025-11-04 12:20:16.033501
3d3b55a9-4a3c-49bc-80f5-45ad6fb07d24	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:16.033517
242f3634-709f-4162-a117-f3d0c014247d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:16.033533
18b330ea-b8ff-4638-8327-e8122c1c5d01	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 661}	2025-11-04 12:20:16.033548
7a51a951-edca-48e0-ad36-231bc7a08b04	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.9}	2025-11-04 12:43:31.18742
0d69ee2c-adaf-4cd4-ab72-032e737e06c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.9}	2025-11-04 12:43:31.1875
9b854224-1533-4a76-84ee-2f21d4602d42	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:43:31.187523
cf531777-54af-4ce4-9f6a-4926e22fde0c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.2}	2025-11-04 12:43:31.18754
42c3642b-0987-4238-baca-360216e41b39	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:43:31.187556
337a4fa5-4a25-40c5-a87e-eddd4c9b9c70	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:43:31.187571
cda5616c-473c-4140-bdea-0e171712c85c	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2056}	2025-11-04 12:43:31.187586
b5114c68-f686-43f1-a3cd-99e926ff7a4c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.3}	2025-11-04 12:44:01.311097
9d575c50-1b30-44c2-8db4-116ceb4deea6	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.1}	2025-11-04 12:44:01.311267
38ffaa1f-9d46-4735-a219-88ea29067bf5	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:44:01.311297
0f836a39-d54b-48fe-8d6a-0894ba3a32e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.6}	2025-11-04 12:44:01.311323
dddb1fcb-02c8-4614-a1c5-deda6630e57d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:44:01.311349
da14b05c-06a5-408f-a209-7350e99a6844	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:44:01.311376
41ecc507-5a65-491f-ba69-713cb2a271da	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2087}	2025-11-04 12:44:01.311397
bc3cff60-b15b-4fba-8795-ad91ee09a150	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.5}	2025-11-04 12:44:11.371298
ade7b91d-8dd1-4d3f-b4da-eae11727237a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.9}	2025-11-04 12:44:11.371459
92916d01-17da-44cd-8ac6-0339efea2686	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:44:11.371492
411c4ce9-b2ab-47ea-90ac-8f3038d6501c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.9}	2025-11-04 12:44:11.371526
acd9f8ed-924b-4189-9c93-824bc95803af	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:44:11.371559
92348407-e6fa-4a31-a668-1479d2f63064	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:44:11.371587
34f178ee-fe88-4e11-aae5-fd2c7338d63c	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 2097}	2025-11-04 12:44:11.371613
6691238f-d328-461c-bbfc-fc267d964338	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-04 12:20:26.045464
da18e6a2-b7a3-4320-b2a9-1372b5b8f7c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.3}	2025-11-04 12:20:26.045537
6d271775-9529-4bc9-8a74-7a9ce8bb193f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:20:26.04556
d9b54ae3-6642-44b7-9b10-32d120cdfbf6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.1}	2025-11-04 12:20:26.045579
24c07efd-7124-4f4b-8a9b-c8e50c14a78a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:26.045595
33f00fbf-6091-4ba8-97c2-5d98addc514f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:26.04561
303fb56d-ec24-4be7-9189-f41c09c7d6be	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 671}	2025-11-04 12:20:26.045625
a2c52cda-bbf0-4e96-8605-be08fb418e63	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.5}	2025-11-04 12:20:46.06615
eba8b903-558c-4fcf-b7a4-17c67993a748	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.3}	2025-11-04 12:20:46.066287
3013247e-5b5d-419e-9292-6581257e2cd0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:20:46.066316
3e926eb0-db52-43a3-923a-87634ee89f0c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.4}	2025-11-04 12:20:46.06634
f6474066-8736-4bb5-a477-5e12e044a38c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:46.06636
77d0a88a-ec74-4302-b4a0-311d42860af2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:46.066381
4f2c07f3-dfdc-4927-85f9-d81a5cc78a41	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 691}	2025-11-04 12:20:46.066402
5f8b3792-e460-4440-a413-531c77d58279	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.1}	2025-11-04 12:21:06.081543
feb0531c-d29e-4c79-b001-699661fe4aee	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.3}	2025-11-04 12:21:06.08162
dc117e22-63a5-4865-a02e-89e5a414ae48	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:21:06.081653
c08201b8-4f41-42f9-aa32-20f97322d9c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.7}	2025-11-04 12:21:06.081679
5311467b-b79a-471a-9bc1-b3b2ae0d6cfb	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:06.081705
72145ef9-f206-48e8-9ea6-e99636236fba	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:06.081728
da97695a-1a0b-4e56-aa4f-3e55cdd5f6f2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 711}	2025-11-04 12:21:06.081751
f41c6ba1-288c-4c67-bbdd-1ceaa4244299	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.6}	2025-11-07 03:20:37.492182
7c79e543-7101-480b-9e47-74fe12baa580	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78.4}	2025-11-07 03:20:37.492283
d27baffb-c0b0-4a72-a691-53737aa9a406	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:20:37.492314
186b3f61-42ae-4cbc-b92f-e5c9fb07391d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.6}	2025-11-07 03:20:37.492336
37dc5259-326e-4e30-8065-c439d53fe7d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:20:37.492356
6b588c1e-d237-460a-9bfd-78a9a69a38a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:20:37.492376
d8bfa44e-3ec9-4694-8cb0-19ce015c4e58	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 404}	2025-11-07 03:20:37.492393
23dd97cd-0606-4f59-8a8d-5c3488f4d7c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.5}	2025-11-07 03:20:57.549097
c07806a0-841d-410d-9776-ba1de31f897e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.1}	2025-11-07 03:20:57.549173
1f3f8ef6-4a39-458f-b051-b34197e0c6e1	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-07 03:20:57.549201
8d11b817-4683-44da-936b-c82b608834e8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.6}	2025-11-07 03:20:57.54922
65949ea3-4536-426d-ba41-9bdd48031e58	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:20:57.549236
92862038-a4d8-4e0e-8adc-0b375b5d17cf	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:20:57.549252
b623b895-18f8-4c3c-8037-9a53d84c8f78	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 424}	2025-11-07 03:20:57.549268
bb9584fc-c7a9-4a36-a9f0-fa2f30a25f04	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.2}	2025-11-07 03:21:47.747474
b1cea0b0-db3a-4b3f-8b59-bedaaa2715a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.8}	2025-11-07 03:21:47.747534
8768e361-20ad-4413-bdee-f57eead5a2a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:21:47.747558
db449f0f-9d05-45bd-bedc-12ceb7cebfc7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.3}	2025-11-07 03:21:47.747577
cda20bcf-0a72-4dc3-975e-bb591ea14273	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:47.747593
d4c6aa7f-f2a7-406d-a9cb-fea5ce564745	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:47.747609
f0d770b0-3bfb-456e-82c7-5b7e9162a5c0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 474}	2025-11-07 03:21:47.747625
946940b2-4051-4585-8e2b-4fe8cde13906	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.5}	2025-11-07 03:22:17.870422
0e3a1cc1-494a-4596-8bf4-f4c2224a8f41	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.2}	2025-11-07 03:22:17.870498
1ca7a665-c4e2-42c6-bc09-93ae6016977f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:22:17.870532
0ec6f633-6c38-4e9a-b61c-784b07ca9f03	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.1}	2025-11-07 03:22:17.870555
0f504614-b810-4216-ba6e-2513a03d9b3d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:17.870577
696b53c9-6042-4492-9ace-92b2bc3d09ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:17.8706
5d60010c-db37-418d-a3ac-e6e7fd0ad460	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 505}	2025-11-07 03:22:17.870621
cc0fa590-b5c3-497b-b9dd-e5bbd177da7a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.7}	2025-11-07 03:23:58.434267
783e6cfa-aded-4559-9efd-db214c84e531	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.1}	2025-11-07 03:23:58.434352
56003d8e-602d-4d7c-8678-c908eccdc715	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:23:58.434379
00346963-6329-4350-927c-6c5c1134ea48	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.1}	2025-11-07 03:23:58.434398
61cf6928-9724-43a7-88e3-1108762f9189	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:58.434414
c4a7b768-ff7c-4aa4-8a14-d63f5213d425	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:58.434429
a5ad16ba-49cf-49d2-90a2-9620290979b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 605}	2025-11-07 03:23:58.434445
95c3b7e8-a20e-4116-aa80-adfce71942de	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.2}	2025-11-07 03:24:18.502502
288fd893-ff1d-45a3-8f4c-78eb9678fa96	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.8}	2025-11-07 03:24:18.502587
b39c4374-b4fc-4d51-ae87-2b2db991a335	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-07 03:24:18.502618
fd11ebd8-d8d5-42f3-8eab-d7d06c6c0bed	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.6}	2025-11-07 03:24:18.502645
20cce5b2-244b-4cf2-99c4-c07ae7685e07	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:18.50267
4c341e25-187c-4958-b537-d9e256ce11cf	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:18.502693
6ddd4017-812b-463e-bc40-d352ecb9c4b1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 625}	2025-11-07 03:24:18.502717
c9a34fa8-b44f-4cb5-a3bd-60ee4b5489b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-04 12:20:36.050928
3805a9b7-520c-4138-8ae3-3f7101178d3c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67}	2025-11-04 12:20:36.050997
4e73b9e8-a8a1-472e-8e98-4ac18b05e759	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:20:36.051029
cde0fe5c-413b-48a9-9cbc-350e51dd964d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96}	2025-11-04 12:20:36.051055
b86c2ca0-5f8e-4f1a-a397-a7c4f99dbaa3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:36.05108
1f5e29bf-a12b-4cb1-a3f0-58b5d4b2516f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:36.051102
a23f9bbf-e77d-49b7-ad56-cb2e3e187719	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 681}	2025-11-04 12:20:36.051124
89ac8866-3d5e-4fec-9e5b-8d1201fa36fc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-04 12:20:56.0715
dde4b3e8-eace-4368-8b1e-175619982c93	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.6}	2025-11-04 12:20:56.071567
80cda80c-a0ff-46d2-8b6f-7488a4232789	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:20:56.071588
b58eaa53-bae2-4f64-9027-9eccdf4dd9e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.4}	2025-11-04 12:20:56.071605
489cb89d-8828-4e69-9da6-60aa714f7e07	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:20:56.071621
2c6ac602-6a69-4595-856a-39d5eb9fb2b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:20:56.071637
774c3164-a192-45ca-8867-f7316e5b9787	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 701}	2025-11-04 12:20:56.071652
ecb53df6-925a-4b58-ae60-a3d0625bd855	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.5}	2025-11-04 12:21:16.088986
c88933f7-8923-4f59-b56e-72f576bc6a7e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.1}	2025-11-04 12:21:16.089062
03faff8b-68f1-4e74-934b-3d4780293a52	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:21:16.089084
5e6f5a48-7277-4376-b3db-82bb802aa223	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.6}	2025-11-04 12:21:16.089103
21f1bb3d-6cac-4ff0-9218-8258ec394638	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:16.089119
ee667472-1ab0-4a7a-9ee4-e62eb66a9d07	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:16.089134
1e0062f8-611a-450e-a28b-d9977fb45a07	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 721}	2025-11-04 12:21:16.089149
44c9766d-a635-4532-9d9f-dc95a96ddabb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.1}	2025-11-04 12:21:26.0966
ee97cf52-4d61-4650-ba0c-d109f92e67eb	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.8}	2025-11-04 12:21:26.096667
ea2b38ff-b073-4e66-9e96-4fe44e14b04f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:21:26.09669
158c7ef7-d381-4f22-9d2a-52b68dde7c1d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.2}	2025-11-04 12:21:26.096706
68ce99b8-d565-42f2-a4c0-4b9cae09fa30	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:26.096721
611f6acd-f3cc-4b74-9dfe-ceba0c19040d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:26.096737
2ff0798f-f128-4c85-9957-2594321d59cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 731}	2025-11-04 12:21:26.096752
705136bb-a8b1-4de0-a50b-54b6451e0e40	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:21:36.110556
5d29c0e5-94cc-433a-8a9c-8dd3bb2d551c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.3}	2025-11-04 12:21:36.110646
732f0a07-297b-404d-85c5-ea236cacdb4b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:21:36.110688
78a6b7dc-2e1c-452c-b5e2-256075955104	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.2}	2025-11-04 12:21:36.110716
298122dd-d9b3-4be3-942a-644ceeb67c9c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:36.110739
59197921-c26b-4219-bbbe-bf2cc135c86d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:36.110761
897e827a-d17a-4f91-a4f8-e49745c809fd	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 741}	2025-11-04 12:21:36.110781
caf3225e-56f8-463c-aeda-96de71631078	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-04 12:21:46.115324
185d3686-4ff6-4edc-9e59-dbeba03cffef	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.3}	2025-11-04 12:21:46.115394
3383dd58-4010-402c-9f0f-2232858acd49	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:21:46.115417
4429cf18-a023-4c59-9fed-c91ba4e6509c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.8}	2025-11-04 12:21:46.115434
933009e3-db68-44f4-9869-f2986437381c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:46.11545
114807f7-5e40-4bcb-b6b1-d42b29f2d233	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:46.115465
05f5c937-15d9-4d29-a30a-c90ef4030079	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 751}	2025-11-04 12:21:46.115481
96211538-c128-443d-914c-a3659becc97e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.5}	2025-11-04 12:21:56.120922
16cba22a-d6df-4e94-834a-58b6305203b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.2}	2025-11-04 12:21:56.120989
ce587d7c-5430-49d7-b232-d1f050fd4941	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:21:56.121011
f4523ae8-4609-4336-8ed0-207f9184546a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.2}	2025-11-04 12:21:56.12115
e8d0dcad-90bd-45c0-a00f-88e432b17222	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:21:56.121183
acdb822e-46a6-457c-bdfe-542239063774	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:21:56.121205
374f3176-85f6-4c2b-8a5e-1ea534b815a0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 761}	2025-11-04 12:21:56.121219
46eb842a-ed7d-42a4-9da4-f7294bc8b55d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27}	2025-11-04 12:22:06.145888
17ccefd7-b958-45cb-abe2-08e54c4a7d12	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.6}	2025-11-04 12:22:06.14596
b8cf9720-2d08-4ab3-a2b3-20cd0b741e7a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:22:06.145983
9637a0f8-beae-4170-b0e4-128790b3d657	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.8}	2025-11-04 12:22:06.146002
3e3df959-9fda-4d86-8cf3-69ae0211f3d9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:06.146018
d2f098bf-e030-4990-b0fe-bc2550043642	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:06.146034
c6504729-5015-49f8-82c4-d3f102dd7505	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 771}	2025-11-04 12:22:06.146048
60785298-0354-434e-92d9-5110639b74ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.4}	2025-11-04 12:22:16.155223
3207bf7d-35e6-4499-92ae-c6e9507c8461	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.7}	2025-11-04 12:22:16.155317
28742856-2b2e-4212-a905-0863ba3f820c	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:22:16.155339
b53cd426-07fd-4276-9118-20fd46bf93ea	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.9}	2025-11-04 12:22:16.155355
7626eba4-a676-4be8-9897-53c0244cb036	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:16.155372
d9ee2cdc-b837-40e9-a280-21e839f459f6	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:16.155387
dce98d41-d77d-448c-9dec-14eadb34cff6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 781}	2025-11-04 12:22:16.155403
ad0e434d-55e6-45b4-97c6-778bffb7b101	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.8}	2025-11-04 12:22:26.155113
564e2910-9ba0-49bf-bb01-f4bc554640f5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.4}	2025-11-04 12:22:26.155253
23958c3b-08a1-4026-8f3a-38a1271f56d8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:22:26.155279
9235a1f1-046a-433b-9c75-a2e64918685a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.7}	2025-11-04 12:22:26.155298
da54d16f-ded7-40c7-be30-ea633480e37a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:26.155315
0d26339b-9e4b-4c6b-8183-58f7fd2268e0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:26.15533
5be04d6a-db0c-4e8d-8fac-d66eaf04f97e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 791}	2025-11-04 12:22:26.155345
ac02a2a8-600e-479b-9526-16b18d289844	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-04 12:22:46.178427
3fb127ef-994a-4e0c-93ff-e01d5ca0ee6b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.8}	2025-11-04 12:22:46.178499
23678277-ae0b-49c3-b7c6-cebf79a8ad29	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:22:46.178524
3336e443-06ee-4be5-ad2a-cd4117cea0ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.2}	2025-11-04 12:22:46.178543
305c8e5a-d53e-496c-8787-0db18944bea9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:46.178564
d4b621a6-8587-45a5-bb49-89b265deef4d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:46.178584
a2887a9f-8764-4e8d-bafb-8584ad43b86e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 811}	2025-11-04 12:22:46.178603
1109ded3-7084-4261-a273-f3a9bcf7adfc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.9}	2025-11-04 12:23:36.5451
a1187974-0269-4568-a5e8-ef94478de8a6	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.7}	2025-11-04 12:23:36.545164
5396a592-9b8f-4379-af95-5078d11feded	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:23:36.545205
f2ffb168-cd41-4b03-8de1-5f4248527899	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99}	2025-11-04 12:23:36.545231
cdd0fb37-d2ae-49ed-ae69-e9b1c8745fba	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:36.545257
c375e580-f792-4ee6-b788-1dd6041b3644	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:36.545278
fdcae846-f131-4b98-afab-256269f52ae6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 862}	2025-11-04 12:23:36.545296
96ed9e43-92d0-4803-a725-123b6701ee39	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.6}	2025-11-04 12:23:46.415945
ad26f1e7-a70b-4d74-820a-2b648ebb527d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.2}	2025-11-04 12:23:46.416093
7a28a243-6ff8-4e86-ab55-f04407782274	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:23:46.416121
fb0eeb8c-f4ca-49bc-8eac-9ac224f841d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102.4}	2025-11-04 12:23:46.416144
0512d24d-9e10-4439-a7b5-1ea092a8d02a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:46.416164
267d2f08-ec11-4dce-bbfd-14a2249b1075	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:46.416208
f0a4bcbb-68b1-4dae-b9b6-5be610e7c634	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 872}	2025-11-04 12:23:46.416229
bd329b11-6003-4f3a-8471-7d99b16dc831	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.1}	2025-11-07 03:20:47.458843
9edbdf96-a3cb-4bee-bac3-eb134de1aa93	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.9}	2025-11-07 03:20:47.458956
0e07ccc4-7d8a-4174-87c4-e686482a946e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:20:47.458997
a87feac3-9dcc-4cd1-abc9-7617352864fc	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.1}	2025-11-07 03:20:47.45902
99a1772e-3f5a-4cc2-ac5c-bd4b8988ce16	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:20:47.45904
57b0b252-b5b7-415e-858a-3a1b19e30979	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:20:47.45906
e5206e31-9cc3-46af-a94a-e7f7a2df731e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 414}	2025-11-07 03:20:47.459079
65963ab5-9192-4786-ad84-90b871624159	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.1}	2025-11-07 03:21:17.618197
f4b1b33d-3010-4504-9198-eca923081c16	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.4}	2025-11-07 03:21:17.618255
88b0ca22-20d8-454b-a611-b42b734df421	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:21:17.618277
ca50e549-f018-484a-b58b-83279cb49601	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.8}	2025-11-07 03:21:17.618293
e561ca49-acb7-4dd5-b504-76a14662f994	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:17.618308
7f980540-4cac-4ea7-876c-4d3985300e32	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:17.618325
fbd5cd05-05b6-4c1c-b570-021450fdc9d7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 444}	2025-11-07 03:21:17.61834
a37fa8f7-2693-4e40-b10f-e1bdf47c23d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.1}	2025-11-07 03:21:27.684694
421c479c-5472-4fbd-8cee-baa34d3b06af	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.4}	2025-11-07 03:21:27.684755
a0d239a6-e3e7-40c2-95ea-dfcebd451cdd	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:21:27.684778
e787db04-116f-4905-a81c-8156a5778324	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.8}	2025-11-07 03:21:27.684795
66f5b632-1088-4e57-b11e-2d0c903fa2d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:27.68481
361422f9-61e1-40ae-895b-0e290442ecf4	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:27.684826
79eb86c5-34ec-410b-b250-2c9dfa354628	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 454}	2025-11-07 03:21:27.684841
2d5167f4-ad09-4921-a3a3-34184f52380c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32}	2025-11-07 03:21:37.728959
62019166-8c36-457a-aaae-d8fd62af3147	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.4}	2025-11-07 03:21:37.729049
688269d7-264a-4515-a3bb-eb1f50ddb05f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:21:37.729076
7c193d1f-8b61-4f28-a4eb-bcd0d41ab1bd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.5}	2025-11-07 03:21:37.729096
a5d8d545-fa75-463a-816d-b9f051a1aa92	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:37.729113
628bee16-9714-469f-816c-00093138fd12	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:37.729129
72d6b1b2-bd5b-4169-9810-6acf77c9d6a7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 464}	2025-11-07 03:21:37.729144
4759c9e0-d0a7-44a5-9d43-db6f74c72d3c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.7}	2025-11-07 03:21:57.815435
8a314c8c-beaf-4c12-89a8-988102e0669f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.1}	2025-11-07 03:21:57.815523
c2fcd0cc-c857-4689-a3a1-fbab63970d5e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:21:57.815561
2de32f76-7d9d-4500-a969-682813f92362	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.4}	2025-11-07 03:21:57.815607
961ec716-cb04-4429-a295-bb066900c9b5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:57.815626
57997158-a0a3-4d08-a461-d21ed856a7bc	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:57.815658
ba4f0548-b292-42e2-a348-798cd73492b1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 484}	2025-11-07 03:21:57.815692
8bae2b75-d228-4930-b156-9b2cbdef460a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.2}	2025-11-07 03:22:07.859774
2a6f4881-a94d-47d0-b801-aa92a0aa8977	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.1}	2025-11-07 03:22:07.859834
da9195bf-fe98-4730-834b-d5e3e38ce7cf	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:22:07.859856
4ece5294-a17a-461b-b7f9-42af6e3b4188	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.5}	2025-11-07 03:22:07.859874
311fee9c-ab9c-44dc-88d6-377762b8f133	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:07.85989
abd94cb3-38ec-44ac-9dce-d7539c2010ff	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:07.859906
b9aee545-67f3-423c-9ebf-cb18aa083aff	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 495}	2025-11-07 03:22:07.859922
50b9ddb6-d126-439a-b5ba-e9a775846d9d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.7}	2025-11-07 03:22:38.011591
b63e460e-6269-49c8-bfd1-ab5a59d21b16	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.1}	2025-11-07 03:22:38.011685
b6c92d4f-dfe8-40f7-a535-addfd08ce755	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:22:38.011707
bd6e487f-99b0-43d6-956e-0ea6389a4abb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26}	2025-11-04 12:22:36.172366
6dfbcef7-eb80-48b9-b1cd-7b9db3e4d8c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.5}	2025-11-04 12:22:36.172511
61371c8a-e697-4ed2-8880-3497c9e60560	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:22:36.172554
1a2d8a67-575b-4cee-923c-0c308809cf64	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94}	2025-11-04 12:22:36.172601
63492540-0343-497b-be05-4ba97e425202	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:36.172631
220b1e47-b77e-4beb-a28e-6398e9b83d52	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:36.172659
3a83b25b-4e66-462b-8522-f025a6d89923	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 801}	2025-11-04 12:22:36.172686
2a1b0f62-63ad-41b6-910a-dccc908fa522	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.6}	2025-11-04 12:22:56.180454
fa811135-c36a-4246-bd86-901eff710365	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.1}	2025-11-04 12:22:56.180589
d46878e9-7115-4276-a084-42cbd232701f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:22:56.180618
2be95118-2538-4c4e-b318-71ca81f9172a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.7}	2025-11-04 12:22:56.180644
f1717669-6938-4558-b324-1898b81d3282	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:22:56.180668
81941aa3-5448-46f8-88e9-b2c34ab55efb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:22:56.180689
abbcee42-e085-4715-a9f8-2e37c0c1f85b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 821}	2025-11-04 12:22:56.180712
beffe398-9600-465b-ad38-9d97d3051c91	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-04 12:23:16.278633
a4f33b27-b5e5-4a9b-8caa-52c246899017	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.5}	2025-11-04 12:23:16.278713
4e40ac88-b8b6-483d-a85b-204d2d7f74ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:23:16.278745
02d719f2-68c3-4738-af09-62a89ff2125c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.8}	2025-11-04 12:23:16.278773
18fa130b-da1f-4495-a399-f08faa2e4c3d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:16.278797
7ffa7e76-6e21-4893-a588-73c7e26077be	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:16.27882
5796fb43-bbbd-4a0b-95a1-f9037bbcfe05	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 841}	2025-11-04 12:23:16.278842
be70337c-cdc8-4f39-b9e1-6105c050d2ea	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:24:06.474803
168371a3-2eaf-4830-8a16-6e881311e9ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.3}	2025-11-04 12:24:06.47487
cf545bfc-98ac-488e-b619-f8cdfaeff374	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:24:06.474896
4cdf68fe-6f0c-4bb6-9226-b32e631875cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.6}	2025-11-04 12:24:06.474917
42eae537-2239-4983-b298-b1454cc406af	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:06.475042
220132de-f349-4fbd-a44e-aa6b5a26926f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:06.475061
2974d5c5-9868-4ca8-b798-01104f48ef57	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 892}	2025-11-04 12:24:06.475076
041cd9ef-9430-4e07-899f-5be13d67688f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.7}	2025-11-04 12:24:26.598824
53335032-cacd-40bb-b08f-497cd764bc26	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.3}	2025-11-04 12:24:26.598981
4858785f-dddb-46cf-a7c5-8319c7897d2d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:24:26.59903
c70d60a6-3cbd-4042-86cc-6fd533751b74	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.4}	2025-11-04 12:24:26.599068
efa30f1f-dfac-414c-a117-77dafa5c247a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:26.599103
d6d03bc2-1955-46af-b4a5-a026f1aa7af5	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:26.599136
39cfc708-6656-46c2-91ca-a524cd54242f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 912}	2025-11-04 12:24:26.599195
2796cf7b-bc1f-4b7b-bcff-c768dc6551d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.7}	2025-11-07 03:21:07.596904
8fb05939-ea5b-4e1c-96cd-e826c247a934	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73}	2025-11-07 03:21:07.596991
2c714537-a59a-4fda-941b-eab12989935b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:21:07.597019
22528237-f462-49f6-8f32-12a7afa0799e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.3}	2025-11-07 03:21:07.597038
8c9cc65e-f9b2-4a3b-8818-1de9b0d5ac44	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:21:07.597056
7c484310-d58c-4200-b468-4ff03992ab7d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:21:07.597072
f14dcf28-9318-4984-b4ba-37571ed186ff	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 434}	2025-11-07 03:21:07.59709
6e1e3eb1-49ce-4d69-ae4e-140a158e0fcc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.1}	2025-11-07 03:22:27.967118
182afd83-7970-426c-97c9-813d12753bac	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.2}	2025-11-07 03:22:27.967179
bc4ddadc-47a6-4845-b7d5-268ff159a24d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-07 03:22:27.9672
e4f89bfe-0496-4b05-9ec9-5dca921376fd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.7}	2025-11-07 03:22:27.967218
7c770b93-87e2-4258-b647-976c5b5c861a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:27.967234
419a72b0-8a18-409f-8358-485df494ecfb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:27.967251
8d1e33e0-dec9-4317-91eb-e6fc193524d2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 515}	2025-11-07 03:22:27.967267
b4da8a12-a8bb-4f00-a279-caa42fc95c43	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.1}	2025-11-07 03:22:48.037903
5ea769f1-3616-4477-9aa7-d10531b981e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78.1}	2025-11-07 03:22:48.037979
68f37bf0-0abd-4038-b4de-36dea4514462	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:22:48.038007
c00c3bf7-a2b3-4b48-8371-b364f6bc2c22	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.5}	2025-11-07 03:22:48.03803
126fe52f-16ba-4368-b77f-cdffd7ff1126	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:48.038051
f81c9f17-b402-4e2c-865d-a9efcb3c022a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:48.03807
684d7890-6795-4f2c-9788-53a9a0bcfc11	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 535}	2025-11-07 03:22:48.038089
08bfa53d-e6d9-491b-9020-462d1a710a62	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.1}	2025-11-07 03:23:18.205854
be1fdcaa-4061-4ac5-94cf-f15bd9d3be54	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.2}	2025-11-07 03:23:18.205916
60ce4910-3789-4c58-89b4-3251476dd8e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-07 03:23:18.20594
6cb54334-7ba6-4c40-ab28-6df0ccbfb714	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.2}	2025-11-07 03:23:18.205958
a7274c72-0c54-436d-a848-d8ede864d6ed	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:18.205988
616836ac-ad71-45e0-ac23-2b3e37c5b184	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:18.206006
2c3c880a-bd2e-4bbf-adec-b37479209fb0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 565}	2025-11-07 03:23:18.206021
818c3758-2594-4795-b571-927e4affdf25	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.6}	2025-11-07 03:23:28.28689
b2d1c2ea-4c63-497d-b60a-69316469b5f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65}	2025-11-07 03:23:28.286951
644dfeab-b833-40f0-abf0-a84a7d7bb4e6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:23:28.286984
1e531c80-eb1f-4639-bb8a-9b85a7d44aa2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.8}	2025-11-07 03:23:28.287003
0830b30d-fb13-4a3c-87b3-2035ad589a7c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:28.287019
dd1ee985-4c58-41ba-b563-95e6fdbfba5c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33}	2025-11-04 12:23:06.208481
f9ccb64e-66a3-4653-a1c9-168954c9456d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.3}	2025-11-04 12:23:06.208593
be2936df-2750-4b85-86a2-84c5a00e3096	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:23:06.208617
6b35f60f-701c-4719-8157-ea9ef7236a6f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.5}	2025-11-04 12:23:06.208636
f673f2fb-afba-4e77-9b97-15891f58535b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:06.208658
911e7d3a-bdba-45a1-8f75-f38ea1b30cf9	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:06.208675
724f74b0-e635-495f-b71e-698a9f06a3d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 831}	2025-11-04 12:23:06.208691
6d5ded29-d433-460c-8b3d-5454e02e709c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.5}	2025-11-04 12:23:26.328327
ad1be3f9-fa47-4708-85da-c43e996cc192	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.2}	2025-11-04 12:23:26.32839
feda0057-ec03-4bad-ba31-8ad0e714cd47	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:23:26.32841
f4a3ddc7-b90d-4c7d-9bb1-3809d1b596e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.2}	2025-11-04 12:23:26.328427
3c016c9e-74e6-4a56-a2d7-95c4cad832e6	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:26.328441
4f7a080b-2d3b-418b-8080-bba9b7adfb4a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:26.328457
89a10f06-addd-4c44-aa46-808b05c2432b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 852}	2025-11-04 12:23:26.328471
6f4c2107-197f-4f4d-808d-ef5b6ee3ee9f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27}	2025-11-04 12:23:56.468824
4d62b99d-941e-4947-a2c3-cda4464cb94f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.5}	2025-11-04 12:23:56.468894
50bf918a-a15b-4490-bba0-c4f5d3478da5	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:23:56.468917
a26a0314-59b4-461f-a65c-ac35965e9b13	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.4}	2025-11-04 12:23:56.468935
506a591c-bb90-4a37-a48d-c3b428f8959e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:23:56.468951
ecf59e0d-41e6-436f-8534-c6db23c172ab	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:23:56.468967
b13950ab-3853-4b29-879b-ae121194d2a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 882}	2025-11-04 12:23:56.468981
ffc69c5c-f283-4a5d-bb87-57fc8f76d6b7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-04 12:24:16.554163
89645ac3-d3d0-4dce-ac25-2ecfdb1c62f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.4}	2025-11-04 12:24:16.554248
350fd20f-bc06-4453-a0df-eb2f87673728	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:24:16.554271
f848ad1f-6695-4e40-bd97-63a278017e7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.2}	2025-11-04 12:24:16.554288
e3911b85-c7c5-4067-8f19-e805fd423c0f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:16.554304
49776fd5-069e-47d7-a6b7-63e079f4ddd7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:16.554319
27d9ef6f-fc28-4bc0-a0cf-fe81dbeb50a5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 902}	2025-11-04 12:24:16.554334
13026130-81a4-4f53-af94-6a7712ee2447	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.3}	2025-11-04 12:24:36.622443
e9f6e2a0-2c50-4469-bb5c-5649d3d7cb34	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.2}	2025-11-04 12:24:36.622552
ad89b88c-a657-428f-949b-a911ec72e806	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:24:36.622576
d1fc0001-c34f-4f2c-8c4b-882ee32d6986	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.9}	2025-11-04 12:24:36.622596
3b8f759e-3fc2-4698-9c47-56c3e5ef409a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:36.622613
555d910e-4621-4325-8868-ccd2f2452bca	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:36.622629
8573bbe0-8b09-4caf-b402-f97c1c6bff0b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 922}	2025-11-04 12:24:36.622643
f34ca57a-a474-4cd8-bc0c-2b19bb22e530	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-04 12:24:46.663162
2b11cf38-e870-4b1d-ad70-86e184ca8cff	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.1}	2025-11-04 12:24:46.663267
29802cfa-4e01-473a-9561-493fc08c00db	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:24:46.663308
e62271fe-8743-4226-bdd7-4210f56996ed	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.2}	2025-11-04 12:24:46.663338
ea68222e-6570-4698-9ede-c52d842ac4b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:46.663363
03bf9c50-f875-4b54-9230-96101b745a5e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:46.663385
9b679a92-696c-46b5-922e-82c66fe2cca2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 932}	2025-11-04 12:24:46.663406
1b4f6eac-e875-4c04-88c1-90b6046ccef1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.4}	2025-11-04 12:24:56.7057
e83294aa-0515-426e-bd89-54b283f228f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.4}	2025-11-04 12:24:56.705767
82df39da-ad78-4dc4-89db-899a1670bc1f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:24:56.70579
c9470c14-9ad7-4507-9be2-fb1b731c487d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.6}	2025-11-04 12:24:56.705807
6a67639f-32bf-43e2-a01e-23716db3c314	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:24:56.705823
98982184-b176-4fbd-9b54-c6db1b44a8ae	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:24:56.705838
9fbc2748-68f6-4f1f-9e81-9877aa70c46e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 942}	2025-11-04 12:24:56.705853
eea4f815-ff17-418c-88dd-8f4c6d0f4daf	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.9}	2025-11-04 12:25:06.718858
a06f5e55-8410-4a71-bbf5-2d1af4c70b64	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.4}	2025-11-04 12:25:06.718972
91143dc3-b964-4a8d-84f2-02c759b1bbb0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:25:06.718994
bb63ea00-0f98-497b-a532-04962e346e86	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.2}	2025-11-04 12:25:06.719012
2ea13a2e-a343-44f7-aa37-3694b3abda22	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:06.719029
bf2a7a0a-6339-48de-b48d-61a8dacd113b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:06.719044
f7195fc6-2fd2-45eb-9074-cf1dc4f440dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 952}	2025-11-04 12:25:06.719059
0cd8463e-fc2d-416a-bcb1-857f7089e9c6	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.2}	2025-11-04 12:25:16.788865
e4bca5ba-dd32-43ed-987f-b4c149b9a08b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76}	2025-11-04 12:25:16.788934
58e26389-1496-4fd1-b297-dfbf06445872	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:25:16.788958
1cef2c16-0bbe-45d5-acdb-9b50e4646ce1	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.5}	2025-11-04 12:25:16.788979
cc7e0276-3143-415c-bf8a-17ff42cfe997	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:16.788997
5d0808b2-ab42-4b38-b6f3-51555bbc9863	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:16.789012
1ba12367-ef57-4774-9524-91cc047c8498	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 962}	2025-11-04 12:25:16.789028
78663230-5a8b-436f-9843-c0bc4d902da9	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-04 12:25:26.833982
bcfc86c0-c8ab-4dba-b1f6-dae60a2c6563	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73}	2025-11-04 12:25:26.834072
fb62ae34-6d01-4fe6-8f1c-3a21f6280d6d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:25:26.834103
f212784e-af1d-4cab-8ccb-6bbc0a9e5205	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.6}	2025-11-04 12:25:26.834127
5d027ab1-1a74-4fcc-8413-0c7de3ce34b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:26.834148
310504e3-71be-4deb-aee2-ad11cf37fe1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:26.834169
29caab72-6b85-4dcc-819e-8b3968a810f5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 972}	2025-11-04 12:25:26.8342
d5ded5da-0900-46f9-9312-d6d2f9dabf28	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.4}	2025-11-04 12:25:46.937249
32476f66-f8d1-4206-808d-0f0f7ce20034	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.1}	2025-11-04 12:25:46.937342
a6e3771c-e25a-455d-a6b9-620518ad2ed5	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:25:46.937374
b64183f9-97fc-4723-a3c5-4c2d7178377a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.8}	2025-11-04 12:25:46.937401
d3d9510d-fb54-4446-af3c-99990ec6db03	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:46.937425
71e46108-0cf6-457a-9fd3-c8d7d7a2758d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:46.937447
59f9571c-8056-4d71-849f-4d35a694c3ce	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 992}	2025-11-04 12:25:46.93747
917e0219-a545-41c5-92dd-ed8169d920f4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.5}	2025-11-04 12:26:37.096857
290056d5-ce87-4b02-a87f-1e21511a1dbb	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.5}	2025-11-04 12:26:37.097001
0b0d4348-71e1-4bdd-a71c-8fe2e2428e30	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:26:37.097061
52edcb94-6d6e-4f18-b9ec-d0a3d2d99de4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.5}	2025-11-04 12:26:37.09711
92aa1810-3d29-46d1-bafa-67c994166cf6	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:37.097145
b58a9484-9253-445f-89b6-b726911ad976	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:37.09723
02e9bad2-4874-4894-892c-278db8e8dbac	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1042}	2025-11-04 12:26:37.097275
f7d4a017-0fb4-4737-b8c1-b61694573e03	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.9}	2025-11-04 12:26:57.218362
aa6ab0e5-ded0-4343-81fb-49f0f47fe937	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.4}	2025-11-04 12:26:57.218439
f4db9a22-49a0-421e-b16a-f697d2efee4a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:26:57.218463
67ce7c2e-0d60-4b67-af06-be13104d0fc0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.8}	2025-11-04 12:26:57.218481
c3de4af1-d9eb-4548-9664-38cc2979a435	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:57.218497
6307ac46-5d70-4e28-8dd2-26adedd910e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:57.218513
75453080-ac42-4c69-9b80-d847a8802ca3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1062}	2025-11-04 12:26:57.21853
8a1af1cd-a24f-4cd6-b78c-806b85353ca7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.1}	2025-11-04 12:27:17.313964
765aa772-3a4b-4a53-8ded-b8f3728a6ff8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.9}	2025-11-04 12:27:17.314028
1cdc657c-d1a3-4c40-93fc-26eb0059b6db	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:27:17.314047
fa3673c5-d3f9-4994-861c-3f5406016061	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.3}	2025-11-04 12:27:17.314064
37d0446c-7443-4666-8503-9e95d9d2e353	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:17.31408
24713dd4-76f5-4aa3-adcd-ea467103a78f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:17.314094
1514a34f-7653-4298-9633-233bf3672de2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1082}	2025-11-04 12:27:17.314109
88aa024c-3925-4feb-9c00-409b3936fc34	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.1}	2025-11-07 03:22:38.011725
a4f531a6-b76b-46ff-84c7-1f141a7f3f6b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:38.011741
8fb9f3b6-ab1b-450d-b171-6e565ba13a56	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:38.011759
df3ad450-ed56-4662-be52-d717f7951af6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 525}	2025-11-07 03:22:38.011775
e9632cc9-e57d-4ca6-b567-7235948b68b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-07 03:22:58.10697
abda4d07-179f-4b4c-88cd-28043e30f960	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.1}	2025-11-07 03:22:58.107038
47b5e32d-7c88-4d65-8f82-e70fc25903dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-07 03:22:58.107061
275666c0-07ae-4b2b-8283-2c655610e7d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.5}	2025-11-07 03:22:58.10708
02f944e8-9f34-4a5b-a1c2-195666e0df98	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:22:58.107096
088eb11b-4d16-4b92-9a96-d436148094eb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:22:58.10711
fcb4b8b5-ac8b-4126-aef8-82b92d3df35d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 545}	2025-11-07 03:22:58.107125
129dd699-f358-429a-9016-c31257baa416	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.7}	2025-11-07 03:23:08.175832
beda48cc-f06c-47ec-8fed-12eb401cd379	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74}	2025-11-07 03:23:08.17589
c1bef8f9-4963-4c5c-b3aa-81502e2b7a95	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:23:08.175912
4e0bd23d-2e00-48eb-a0b6-1c9afd2a0ab4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.5}	2025-11-07 03:23:08.175929
03c5b3f7-79c9-400e-9932-c9a5499cc945	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:08.175944
dd84482d-7d0b-44a1-ad20-4da09fdac264	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:08.175959
13c45bc3-50ba-4e27-a562-8f0ffb29eaca	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 555}	2025-11-07 03:23:08.176
f369192d-ef3a-4d3f-9587-be4bf2875b43	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.9}	2025-11-07 03:24:38.617194
cc738af4-342f-48fd-9f00-e2d9cdbfacf9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.4}	2025-11-07 03:24:38.617264
40901e55-495e-4215-9ffc-81ef40c128c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:24:38.617289
e2fa46f6-2a56-445b-9c66-68dd92724bca	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.3}	2025-11-07 03:24:38.617307
7e57367f-866a-47e9-8eb2-5729260fa824	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:38.617323
550fd8fe-fce5-4b21-bad5-76d5ae18ea42	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:38.617339
4bcae4a9-696b-41fe-81b7-9e153da44356	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 645}	2025-11-07 03:24:38.617355
6d35bd28-8262-410e-b4b1-eb36bcfb4958	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.5}	2025-11-07 03:25:38.907332
90c151aa-2890-4f2f-8f7f-662bae5189c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.8}	2025-11-07 03:25:38.907412
3c3de4c6-965f-43f5-b69b-5017c7e84f04	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-07 03:25:38.907439
1be019a4-075c-4065-a397-3da61fbab43b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95}	2025-11-07 03:25:38.907457
38e4e80f-f623-4504-95e1-76cc923d8e80	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:38.907473
ffbdf883-9aae-4f7b-8fc3-3b9a211ca33b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:38.90749
f6f773c6-ef1f-4d30-93be-81f754d1f446	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 706}	2025-11-07 03:25:38.907507
407d14e8-ac05-4f7d-9337-1cd76ac450e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-04 12:25:36.841361
6ca4b505-3e3b-4d72-9d16-d25579d1f689	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.2}	2025-11-04 12:25:36.841435
8e56e58c-23d1-4c71-96bb-007e7fcf6629	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:25:36.841457
eb481ace-660a-413a-8a61-5a08be80a6ca	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96}	2025-11-04 12:25:36.841474
a6120495-5513-4a22-8c62-8f57cde817e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:36.841489
8d8669af-9932-4fb5-bec3-6f2dfa45a6ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:36.841504
b4295b0c-2471-4760-b178-3ba062d9d687	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 982}	2025-11-04 12:25:36.841519
ba6fc954-b37b-445a-9401-848fa6015181	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.6}	2025-11-04 12:25:56.957362
0649f00b-b71b-40d0-98d3-544bb5962711	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.5}	2025-11-04 12:25:56.957515
1dd68ea2-cc42-4825-b325-5741897301d8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:25:56.95755
ccf6a4c9-fe60-4dd6-99dd-ae461c51ecf9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.1}	2025-11-04 12:25:56.957579
059d7702-63a3-4c89-a980-58f17e3ad4d4	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:25:56.957605
159e1ff8-b393-4159-acc1-0ba3134865de	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:25:56.957629
784a0c9f-fbcf-413d-af08-d307f33bee1b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1002}	2025-11-04 12:25:56.957654
1bf143bf-bc7f-492f-bf01-992493106d50	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.6}	2025-11-04 12:26:06.974426
0c845657-6b73-486e-a2ea-65888838b0a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.5}	2025-11-04 12:26:06.974529
f349a326-b1a5-4239-89ee-465f2ee37c5b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:26:06.974555
2bba1edb-ecc9-49b3-a9e8-a075f2d3655c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99}	2025-11-04 12:26:06.974575
4cc0eb4d-b9fe-4b7b-a64d-96b2bae5315e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:06.974591
622d70fe-91aa-4cc7-8ffb-6e48973466ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:06.974605
b20157e1-2f87-4f90-9d64-96c80b9d5592	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1012}	2025-11-04 12:26:06.974622
6f1d1480-769c-484e-981e-b3917b6fd120	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.9}	2025-11-04 12:26:17.03446
76ea4f30-dde6-4725-9c27-b7b68b382b68	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.5}	2025-11-04 12:26:17.034522
01af8694-ff32-4a5e-8967-f4ebf52589a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:26:17.034545
4e2ca020-891e-457a-95d8-1122f472fa9e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.5}	2025-11-04 12:26:17.034564
5049b2a0-95b9-4a2f-aa28-69663ead14bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:17.034583
273c286f-9c09-447e-b973-b458cb8445e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:17.0346
d1bfa0ed-5ffa-4c8c-b300-0eb20c558693	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1022}	2025-11-04 12:26:17.034616
17e99685-b3aa-4145-87d2-e619718f93a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.8}	2025-11-04 12:26:27.075595
88257f27-09f2-4146-b6b0-bd81ac6b6137	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.9}	2025-11-04 12:26:27.07572
7c91fa73-88d6-4e6e-a18f-66ea8f38385f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:26:27.075749
e7df27c8-b04e-405a-bbd6-0f17df2d8a8f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.8}	2025-11-04 12:26:27.075775
437c6f52-ab31-49db-8aa0-1c7ffbe2c7f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:27.0758
04e4f7d8-a4ea-4864-9a27-75075be6ce93	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:27.075835
a270a6bf-a43b-4e78-b6d5-efdcd9e4bed1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1032}	2025-11-04 12:26:27.075862
b0a515b9-6dbc-46e8-83b3-c730394c4d22	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32}	2025-11-04 12:26:47.17796
b14c5096-13ba-4084-b6e2-0f2ffd99b335	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.5}	2025-11-04 12:26:47.178064
33467309-f56f-4a49-9bea-e574201bb6cc	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:26:47.178089
17f31232-709e-4366-9956-5e05126bebe9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.5}	2025-11-04 12:26:47.178107
ca816e5a-964c-47fd-863c-d34be1e14fa3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:26:47.178123
201cea83-11a9-43c3-94b6-9f8562a21e04	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:26:47.178139
a2f2541c-efdb-4799-94b3-6cf0f44e692d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1052}	2025-11-04 12:26:47.178156
16dea7e2-8b61-497d-94e7-e72c57340ead	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.3}	2025-11-04 12:27:07.230554
83d00f9f-a62f-4278-8b8f-dde676b8167f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78.4}	2025-11-04 12:27:07.230645
4223fb37-916e-4c2e-9498-38183e5312d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:27:07.230686
e4ab4718-5ed9-404d-a6c5-a6ea569fa85e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.1}	2025-11-04 12:27:07.230709
54f8802e-349a-4875-a855-4fc35669a73a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:07.23073
456fd880-a020-4a78-8628-17bfe37d6583	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:07.230749
67b719e4-805f-4306-8acf-f5dad5a7699b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1072}	2025-11-04 12:27:07.230769
4ce6f6a8-2bd6-4177-9c6e-564d71348d0e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.9}	2025-11-04 12:27:27.339521
ba4b7fb1-baa7-4028-b5de-9fe1adfe510e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.6}	2025-11-04 12:27:27.339589
b81d4cf1-c84e-478f-b3a2-070e08f33428	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:27:27.339609
3814a174-7b58-46e9-b48f-d7fa72c30a38	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.3}	2025-11-04 12:27:27.339626
437a4c57-3703-475c-b3f6-5f8d7aeeb237	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:27.339641
88038db7-6efd-4cc8-aa49-5065ff2978cb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:27.339656
94909512-fff8-4549-ac29-9e8f30141ed5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1093}	2025-11-04 12:27:27.33967
b7a3d31f-ca1f-4b79-a5a5-60b94695aeba	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.1}	2025-11-04 12:27:37.35432
7b8efe14-686e-43ad-8eb9-6e8aac511302	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69}	2025-11-04 12:27:37.354389
1abb14c9-b16c-45f8-b503-51ca93d0ca30	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:27:37.354412
b98923d4-f7e6-4c7d-aff2-47aea1bdfe22	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.4}	2025-11-04 12:27:37.35443
0a74e349-2fb3-4445-86c6-b02bbc779c52	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:37.354447
d3e0c1c5-bc5f-4b90-9ade-2de2d2d143ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:37.354464
38cb0176-59c8-4aa2-8b20-a2643ce84cfd	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1103}	2025-11-04 12:27:37.35448
387515ec-07cf-4ea9-94a8-31f5a5b6b91b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.7}	2025-11-04 12:27:47.411747
2d486e83-f3c9-4d2c-b9cf-8cacbb835908	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.8}	2025-11-04 12:27:47.411808
d96b0cfa-1f50-4d0f-8b5b-da6b75e73e13	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:27:47.411829
85a3656b-ed0c-4f65-a81c-e6181731ac8d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.2}	2025-11-04 12:27:47.411846
b1fe7d6a-319c-4d77-95b8-13dc3f4bca2f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:47.411862
37baa2f1-dd40-4bb5-910c-34c8a102176c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:47.411877
1a8b2f1f-36cf-4c07-9789-f89cf10d2123	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1113}	2025-11-04 12:27:47.411894
f35c8954-e3d7-4cf1-b458-8317b4a0024b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.5}	2025-11-04 12:28:37.593434
e92fa141-e0bd-457d-8ac7-f3b24404334c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69}	2025-11-04 12:28:37.593498
018fe8d3-c0af-4634-bd58-c9adcbbed733	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:28:37.59352
5c63ca0e-bfe7-4ca8-8049-c624d0e32d4f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.6}	2025-11-04 12:28:37.593537
b9706939-041a-4bf9-b1e0-27b262323a48	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:37.593553
8a2332a4-4003-494e-b57e-0a510ed11d83	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:37.593568
08203e88-a484-41f6-a741-c9d125ddaa48	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1163}	2025-11-04 12:28:37.593582
205afbfe-7584-41e3-8c10-9bb6fc71f45b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.7}	2025-11-04 12:29:37.836475
f207a511-441d-4c5a-a221-5db5365a6fbd	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77}	2025-11-04 12:29:37.83654
fd3e733e-8ef4-497c-be2c-3eca3d9fbe00	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:29:37.836561
354f38a9-eb6b-484b-8882-fb6222bc87fb	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.6}	2025-11-04 12:29:37.836578
723daf7b-3553-4103-8a1b-349b15256992	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:37.836593
9c970544-cab5-4fe5-86aa-bf305cf8a4e1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:37.836607
56d50e94-344a-4868-909b-bf63e24060ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1223}	2025-11-04 12:29:37.836622
60d9b722-961d-42a4-a3f5-d9afc1ba8085	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.9}	2025-11-04 12:30:38.075379
36cda9bf-2d21-4e2f-a00f-628bdff5b467	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.5}	2025-11-04 12:30:38.075447
836fa77e-7358-49e2-8c38-9bd096361875	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:30:38.075476
40194844-6267-4143-bccc-b5f414914a98	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.1}	2025-11-04 12:30:38.075499
c44fb5a7-0b98-4d0d-9eb7-98c6234663d7	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:38.075522
384ac716-7b7a-4dd3-b55f-11be2383e7ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:38.075543
3b129f4a-d671-4fb1-9b59-c802138e960f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1283}	2025-11-04 12:30:38.075565
2d5d941d-6dc4-4865-a580-4a83af45b788	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.8}	2025-11-04 12:30:58.191038
f09990cc-8367-4a66-8e24-8ac704138d3a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.7}	2025-11-04 12:30:58.191105
6c43498b-4b2e-4b10-b963-b79f82b4f611	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:30:58.19113
96043a84-55cf-4ae1-8f51-c04a5a5b6321	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95}	2025-11-04 12:30:58.191149
304c2382-f4c6-41ac-ab3e-582e0e0e49b5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:58.191167
70854e12-6a5b-4470-8022-bea80ae28b1b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:58.191202
8b22c96c-29e1-4ffe-a2cd-86333752ce49	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1303}	2025-11-04 12:30:58.191228
1116466c-e4d9-4280-899c-a58d64160b59	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.2}	2025-11-04 12:31:18.260612
b8ba5030-5577-49fc-ba0b-264e1ea51459	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.7}	2025-11-04 12:31:18.260731
70af834d-5a4b-408c-a34c-cc7914f216db	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:31:18.260761
04c294c4-7b18-4ae9-b594-787795b9bc79	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.8}	2025-11-04 12:31:18.260785
8c83af32-a633-471b-ba2d-38b246a3e998	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:18.260806
8890ec17-006d-4087-a990-de1092ed06ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:18.260827
62cfed56-5af5-41dd-b96c-fc0678220f01	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1323}	2025-11-04 12:31:18.260847
7c4ae9ab-295f-40e8-8714-f48f8306cbf0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:28.287035
9aa004a7-0898-4f12-ab57-a6c03bcfb228	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 575}	2025-11-07 03:23:28.287051
f447fd91-7711-478e-86d8-f1ffd5e3f301	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.1}	2025-11-07 03:23:38.326196
4a3c3e67-4852-4974-b992-a4f0e43f2529	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.1}	2025-11-07 03:23:38.326257
d8a67744-bfe7-4464-a5a7-95d49ac28276	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:23:38.32628
20367405-9cbf-4ea4-8406-83cae7938218	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.9}	2025-11-07 03:23:38.326298
6773428e-3124-4c06-9574-02818960d079	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:38.326313
88f73428-e366-432d-b074-96b48478f76b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:38.326329
10607b37-11a9-4c93-a051-daba3a6fbdf1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 585}	2025-11-07 03:23:38.326344
4a7bc44b-79e3-4b64-b070-5552444b5680	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-07 03:23:48.377947
cf63d46c-9239-4e11-b7d0-0c70a3c7b4d8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.8}	2025-11-07 03:23:48.378025
f203e29c-6327-42ed-9fcb-f58dbba5bb50	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:23:48.378051
53ea1e06-9b0e-496a-97f2-414b787a1e86	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.3}	2025-11-07 03:23:48.378071
39005dd8-5360-4600-b882-3da93607c6dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:23:48.378087
a386e244-ead2-4453-a44c-b4c4d39a91e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:23:48.378103
1a9c7b8c-3834-4624-b6c8-bb6f19a179d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 595}	2025-11-07 03:23:48.378118
9dd6169e-a83d-42ad-90d3-e221df3f41e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.9}	2025-11-07 03:24:08.486349
ad5e023a-333a-4849-bb9d-46e7ffa9646a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.7}	2025-11-07 03:24:08.486412
6012ca8b-ffc2-4319-84af-1b1060a75efc	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:24:08.486437
f7f3cc3e-3fd8-47f7-ae52-6a6a0a29a357	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.3}	2025-11-07 03:24:08.486456
dde4541d-9929-46a8-a145-2bb5da6d71a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:08.486471
70c5a945-09ef-42c7-ba1f-6deaff3a607b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:08.486488
509c35b9-be0a-48c8-aa07-de2c070a9a53	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 615}	2025-11-07 03:24:08.486503
73722f31-ded4-4456-9fad-02a33ce7027f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.3}	2025-11-07 03:24:28.561844
ae99acf3-c67c-4359-999f-494888965adf	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.5}	2025-11-07 03:24:28.561907
e118dc83-e2d9-4616-9c83-0b988fa05843	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:24:28.561929
b492cc3b-6c08-4840-ad3b-6a26fa081c15	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.7}	2025-11-07 03:24:28.561947
9a67ae24-ac30-410d-8136-506047892d3f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:28.561975
93c67765-10d1-435f-aebe-5f4680d6fc94	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:28.561992
30c38601-ee44-429f-9521-6469a17d9f8f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 635}	2025-11-07 03:24:28.562008
06328fd9-e39b-4114-af61-5bc6818335a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.6}	2025-11-07 03:24:48.637357
2dd19a65-9e45-42d7-92d3-a20d3fdc6c3d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.3}	2025-11-04 12:27:57.454481
d2cc73c8-cc6b-4795-9b46-34f64346c3f9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.7}	2025-11-04 12:27:57.454554
857de5b8-e24a-4697-bd80-0a978b320365	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:27:57.454581
2598bf11-acaa-4470-9bbc-1d5515413788	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88}	2025-11-04 12:27:57.454604
171b26c4-2a8a-4290-a2f1-047a8969ed3a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:27:57.454624
bce97d48-8377-47b9-8f4a-38aa8fe2677f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:27:57.454641
0b885bbc-0b26-4e76-868b-6a56bef54322	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1123}	2025-11-04 12:27:57.454658
0c072787-6e22-47be-a6f6-a08aa7f96d4e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-04 12:28:07.468494
db4a45ea-3606-4251-9471-50f4548577af	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.2}	2025-11-04 12:28:07.468617
3ed61fee-6047-46c6-a1d2-22cf336d79bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:28:07.468645
72a0031b-3169-4ec8-a0f5-ab00809bc60c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.9}	2025-11-04 12:28:07.46867
fc0050c1-78e9-491e-97c8-f44cfe9fb582	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:07.468694
fa540386-425b-4185-8900-e2b30851984f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:07.468718
e612cd10-6cac-4df7-9f86-e4a492371d02	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1133}	2025-11-04 12:28:07.468739
2e99ab11-0469-443d-89dc-2f3ca2d17095	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:28:17.536351
e04539c3-86d3-4326-a9c5-b54d9bba41cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.6}	2025-11-04 12:28:17.53642
6a1fc20e-08e2-46ae-b90d-40ee3051aa6d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:28:17.536444
1186a854-9d4b-4636-a7f7-bd56736fa57c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.5}	2025-11-04 12:28:17.536466
430b6086-c530-449f-a466-14491342dba9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:17.536485
2a542cc7-3b6d-458c-a269-0cbd41275aff	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:17.536503
d499a756-57bb-4879-b20a-15ccc7427e9d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1143}	2025-11-04 12:28:17.53652
ede607a1-1509-4d0a-96cc-70586c90e295	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.8}	2025-11-04 12:28:27.587849
1782f2dd-3bdb-4c87-bcd5-74aa96cf3d0f	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.8}	2025-11-04 12:28:27.587916
b17fdce8-fe55-4a2c-ab84-72a3a43fa07f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:28:27.587937
05585a8c-d456-44cc-be80-7d6c92ee5ad0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88}	2025-11-04 12:28:27.587954
7fedd80e-dcc1-422d-9a9e-144e08c75e19	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:27.587969
9b3a8570-bffd-4520-9a96-3e4dca6cb9da	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:27.587984
d4a81a98-c609-4245-bc16-bc3977f91d3c	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1153}	2025-11-04 12:28:27.587999
3fa25f19-7a2d-422a-8b30-bbca50e6217b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.2}	2025-11-04 12:28:47.66073
af439e72-3deb-422c-be6a-0a1ad20fd9ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.8}	2025-11-04 12:28:47.660794
591c556b-54f8-44a7-8af0-03412a55987b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:28:47.660816
a9961636-3f4d-463d-a10d-a13a52f00178	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.4}	2025-11-04 12:28:47.660834
435be4f7-cd66-4f42-88ae-323108e67ba0	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:47.660849
7571818e-4660-4c03-a640-24781e3689d7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:47.660863
2338d476-ec26-430c-bdf4-19ca2a76b2d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1173}	2025-11-04 12:28:47.660877
89d4023c-39e3-4dcb-9e48-490a3ce83ecb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.5}	2025-11-04 12:28:57.697579
5795d38f-8455-4db7-9473-0ed18a8b76d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.5}	2025-11-04 12:28:57.697645
0edc22ed-068b-40ce-b02b-256cfc7c618d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:28:57.697667
3c58e607-cde2-46a9-ad30-5b952daf549f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.5}	2025-11-04 12:28:57.697684
7b08c32b-4200-4ed0-ba09-41f4c01404dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:28:57.697699
855d75bd-b85b-49d1-9e0e-df28a8510770	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:28:57.697713
0bb8cbd6-2949-4e18-8323-5c2108a8a61e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1183}	2025-11-04 12:28:57.697728
6ca6ef53-6f95-4661-b40e-2a93271d4fad	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32}	2025-11-04 12:29:07.703505
050961bf-92a2-4fd6-a0f6-04fe70e4c672	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.1}	2025-11-04 12:29:07.703577
e7eb6be7-d2ab-44dd-9f19-378ee67a12a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:29:07.703608
b2cdeac6-9143-40ad-b132-1d0c4ef26ef3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.5}	2025-11-04 12:29:07.703634
38c9dc16-38eb-4705-b8ef-629efa1ddcdc	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:07.703658
9c8feeb3-4dd0-46fc-a764-dbb40ec3865a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:07.703681
9f0a3de1-2f44-426b-a985-4f762a628410	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1193}	2025-11-04 12:29:07.703703
001dd748-19b4-4ba0-9ad1-483dbc892b6e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.8}	2025-11-04 12:29:17.777096
0a4df62a-3842-46ff-8b75-31ccf60b2c08	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.8}	2025-11-04 12:29:17.777163
9dee486a-c33a-4518-bf1c-450865d65c0f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:29:17.777209
b318ab59-9d0c-452b-af57-7573fe204327	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.1}	2025-11-04 12:29:17.777231
821541f8-3412-4f72-b0df-cc50140bc7f5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:17.77725
b3cdf2d4-e66d-4520-8cab-1728e4fba5b8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:17.777268
a1d03461-b691-4954-8742-13e14e6fab94	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1203}	2025-11-04 12:29:17.777286
829b4d8d-5e02-4c6a-9e65-6b787f555982	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.5}	2025-11-04 12:29:27.810038
a6b3738c-416e-4153-94e6-f7fbd13580e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.7}	2025-11-04 12:29:27.81015
2c43d557-c91b-48f4-a4a4-7451d19ed825	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:29:27.810185
ddca2761-aabb-45b0-adde-211b6aaf8782	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.5}	2025-11-04 12:29:27.810208
7577c570-2f89-4b2a-8d71-6edc70f6a969	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:27.810228
bb8366d9-2934-41bb-bdc6-cc3cb7c9077f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:27.810244
5df498bd-9ea6-4e85-b15d-a2f6e4b214f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1213}	2025-11-04 12:29:27.810261
f420fa06-c865-499e-a238-f68a1067e85f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.4}	2025-11-04 12:29:47.89566
b58065ef-b9c2-439f-982c-03825536c617	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.9}	2025-11-04 12:29:47.895721
fe731262-6fc6-4544-9058-fd47953f2264	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:29:47.895746
a2d3639e-8fd8-41a2-b97d-2b025a3288b9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.4}	2025-11-04 12:29:47.895767
2b7e6b2f-fc74-4a5d-bdec-09ec4b75c5cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:47.895786
c419f78b-765f-45fa-806c-f468c1ba2879	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:47.895804
43e588d7-7fe2-4ca7-b816-e010748601b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1233}	2025-11-04 12:29:47.895822
894c5ef0-b51a-4891-93b3-afd11c3b8742	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.1}	2025-11-04 12:30:07.958162
8d8d3e6c-1d5e-4d37-9d77-6c5d830cc764	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.4}	2025-11-04 12:30:07.958238
02f0d00b-beb4-4cb8-8889-1d61db6a00fd	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:30:07.958262
ad192cd9-f3ea-4e36-b4c3-b4435817a916	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.9}	2025-11-04 12:30:07.958279
ef423ced-21f7-47aa-9f4b-b8a2f70718b5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:07.958297
7c908af3-f44e-47bd-8654-643b73e6ea05	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:07.958315
2c868607-5d23-4b6d-bf75-856a566c1271	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1253}	2025-11-04 12:30:07.958331
4089fb01-03fa-4c96-9aba-1a299c5fe091	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.8}	2025-11-04 12:30:28.071003
672b3e02-9dec-46f0-bb31-0c0010e8f3d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.4}	2025-11-04 12:30:28.071126
c9a40b7a-9825-4ecb-8ee8-31ed9f765bf5	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:30:28.071157
375165e1-6194-49d7-822c-657af617a63c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.6}	2025-11-04 12:30:28.071197
886a47fb-3fcc-4562-8476-8b7d3d62074b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:28.071223
d28e188a-4f53-415b-ae7c-687efb2d68bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:28.071244
04afb5ca-b9fd-41ea-b748-15d6473553b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1273}	2025-11-04 12:30:28.071263
7bacdb4d-8551-4db5-b12c-fbc292e563a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-04 12:30:48.142192
fc70aa38-ee8d-44f3-a1c5-8493967ec929	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65}	2025-11-04 12:30:48.142364
f1bbb06b-0139-48be-8c6c-4bc4ff87eb15	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:30:48.142388
40d6535b-cec7-44f4-86bd-6d5159c7d215	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.2}	2025-11-04 12:30:48.142407
c048310d-09b6-4c80-8ca2-25d487d5ddf6	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:48.142423
f82def89-3ab5-41bb-b3ad-d82238adc292	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:48.142437
b99439e5-a299-4aef-b65a-88c317cad751	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1293}	2025-11-04 12:30:48.142452
52c6bcd5-c568-49a8-9038-8010910e9b91	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.8}	2025-11-07 03:24:48.637426
99169a88-61e4-4d4b-ad1d-329a8d54355a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:24:48.637453
6362e35e-78a2-46f0-92e6-75499d8013ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.9}	2025-11-07 03:24:48.637474
f4af28e0-89dd-4ed0-bf33-fea9cb3cb605	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:48.637494
606f533a-98c7-41fd-8cd6-d9352acd0e22	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:48.637517
de177b84-d93d-4ee0-b599-ee4b4c2059f8	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 655}	2025-11-07 03:24:48.637536
a3615e1e-e921-4776-8f8c-87ac4857e535	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.7}	2025-11-07 03:24:58.697246
af7fb0a4-f7ac-48c0-9310-1cf91ae9c6ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74}	2025-11-07 03:24:58.69733
f965b9bb-9daa-40b4-8d95-26f327fc5d70	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:24:58.697355
7edfab0d-e459-4c53-8dcc-494e3bf5f184	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.5}	2025-11-07 03:24:58.697374
254ef509-426e-4b2a-af9b-06fd5752155b	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:24:58.69739
a48e5aa4-6efa-4cb6-a3ef-6e2e55e1b196	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:24:58.697409
6f3f2d60-2e1e-4308-807f-8fb741803312	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 665}	2025-11-07 03:24:58.697427
3c2391b6-7bc1-424b-9f5e-fe5e44ebb4ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.5}	2025-11-07 03:25:08.752037
fd4914bd-cce6-4701-9920-d49e9aeaf018	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.6}	2025-11-07 03:25:08.752099
3c3dd63d-cf9b-44fa-8e1a-67ff0d8e06bc	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:25:08.75212
cbccd481-3e2e-48b2-8e4f-fafb1e193d70	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.1}	2025-11-07 03:25:08.752137
1ba2c927-e994-4e09-9a21-860fc2f2f7c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:08.752153
17aed3bb-0959-4c1d-b7ef-8dad24142949	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:08.752171
e214df1a-2c2c-4fbe-97a0-9a18ef16aad7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 675}	2025-11-07 03:25:08.752188
1b0f9341-8e71-4407-a8d4-c64c19be2cb7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.5}	2025-11-07 03:25:18.770907
10adb9a0-eadd-4bca-985e-53ab27ac2fe0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.7}	2025-11-07 03:25:18.770981
d44b49de-ec0f-4616-a4fb-c4f3a8ea24e7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-07 03:25:18.771006
58d8aa3f-4cfb-4557-bbaa-602c46d9c947	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.8}	2025-11-07 03:25:18.771024
8d69630d-aa64-4aa7-966e-a9e723ea9548	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:18.77104
66c83559-5314-41e0-95e2-58a166a42ac3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:18.771055
e8df06ae-577d-4964-8ba0-fd37c81b4c80	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 685}	2025-11-07 03:25:18.771069
af9a3320-79cb-41ba-8d71-4518ae4595d8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.7}	2025-11-07 03:25:28.841719
5f9cecf8-b491-4222-90cc-798b52ccf6d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.3}	2025-11-07 03:25:28.84178
f0ca2900-8e71-4d97-b34e-a2ada9663785	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-07 03:25:28.841804
d48c62bf-a0c7-4348-a8dc-5df66a9222a3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94}	2025-11-07 03:25:28.841822
fa1041d3-3b44-4ebd-8b7e-15e7031489fe	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:28.841838
fb525316-b38c-45d4-8176-1c373e56ce3e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:28.841853
b52e77cf-e275-4885-9307-c58571db287e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 695}	2025-11-07 03:25:28.841868
ad5698af-d490-4fad-b77e-b4c00e8994e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.7}	2025-11-04 12:29:57.942169
bd22acd9-643e-46cb-ae14-6d2c57fd9494	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.8}	2025-11-04 12:29:57.942255
0f1e27e7-d722-48c9-9e0c-0190802f9093	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:29:57.942278
3fd08290-0bb5-4451-b4f6-3b08958bf7e1	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85}	2025-11-04 12:29:57.942295
27cf0aea-4730-4c17-970b-3308cf2bb39d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:29:57.94231
d3283f01-2956-4bda-9614-ffba1b2658d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:29:57.942325
295394d2-4574-488c-b61a-47632758dbc7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1243}	2025-11-04 12:29:57.94234
5b3f8e7f-380f-4a53-85f9-95cb775458e1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.8}	2025-11-04 12:30:18.021144
ca779640-25bf-4387-b371-bb1083722f7a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.6}	2025-11-04 12:30:18.021238
61e14600-a87b-454e-81bd-1252f23dbeb0	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:30:18.021266
9d113177-f2cf-4a29-8def-c16c7934fa4a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.8}	2025-11-04 12:30:18.021288
e28fbbbe-a6f6-416d-88a3-b2f683201839	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:30:18.021311
04d5fa75-4144-4e1c-bd7e-e29d1548b25c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:30:18.021328
318be626-5c62-4f58-b94b-3241a8e325e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1263}	2025-11-04 12:30:18.021343
cbc81f1c-c1c7-43cc-83dc-77d399b30b21	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35}	2025-11-04 12:31:08.198531
39c96a50-4c43-4ef0-a568-2376e98ce1cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.6}	2025-11-04 12:31:08.19863
1cbe3b64-7311-405c-9ba9-4a819a05ff36	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:31:08.198653
c733d77d-07bc-4866-91b8-a81ff42aa2a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.1}	2025-11-04 12:31:08.198672
100952bb-73d8-4d21-a9c9-91c4d93aef17	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:08.198688
91265b89-f2e1-4d65-b22a-9b383fb64538	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:08.198701
c5a9f9f6-75b1-44bb-b0ce-25d9a9a1aed8	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1313}	2025-11-04 12:31:08.198717
f9901777-de9f-45f9-8845-ca83a0395d4d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.2}	2025-11-04 12:31:28.307522
a7ae8fec-752b-4b42-8b72-a345bb9db2af	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.4}	2025-11-04 12:31:28.307697
1d66afab-1202-44e6-9680-6a6e2ab8a1d8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:31:28.30773
c5f063df-89b9-48c3-8822-cdf4dd0293de	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.5}	2025-11-04 12:31:28.307755
43f34cb9-b099-4963-b1bf-59cb871f2314	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:28.307779
e96fef01-b0c5-4e5a-89f6-44c40acb00f2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:28.307799
9efca0ae-9080-4f89-80e9-9536190bff8e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1334}	2025-11-04 12:31:28.307819
20b1d930-4e75-47f0-ae95-824c05a36de4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-04 12:31:38.326441
17224335-ac03-4b00-a1f2-2549392aca5c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.6}	2025-11-04 12:31:38.326594
a443870c-1ad2-4b9b-9410-606fe49afaf1	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:31:38.326618
ac527519-cb03-4ae7-901f-56a54ab273fe	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.7}	2025-11-04 12:31:38.326638
0ee6ba9c-e4f1-426f-b75f-59f8c3a6a11a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:38.326656
9b47bcec-efd2-465f-8a5b-67369a1beb3b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:38.326673
6c11753d-554c-4893-8be5-dd6fceda6743	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1344}	2025-11-04 12:31:38.32669
51b64cde-eda2-469a-8de2-de3d5aaff34d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.7}	2025-11-04 12:31:48.392233
f65562bb-0cde-4aac-9853-1f041bba35e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.5}	2025-11-04 12:31:48.392301
76235289-8748-4f4b-94cb-5b734a1925d4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:31:48.392322
8fc221c7-7f70-48c3-a50f-a4b3a15b294c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.8}	2025-11-04 12:31:48.39234
d06aa546-a752-455f-8aef-fc0291fbd59f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:48.392357
abd29c6e-8a58-4640-84da-6f173eef309b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:48.392373
0ef511af-305c-43d3-8e18-6ed3ba87d68b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1354}	2025-11-04 12:31:48.392388
b2fea9dc-83b2-4a55-8abb-63a6342d79de	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.5}	2025-11-04 12:31:58.438044
cd08e8f2-aa3c-474f-b7f3-dafbc0741542	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.5}	2025-11-04 12:31:58.438141
a2be77d7-8370-4d98-a2e8-4c0a134b425f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:31:58.438198
3c44649e-6fa8-48c0-9135-cab6decfe860	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.3}	2025-11-04 12:31:58.438238
9f9c3483-a56a-49e3-b796-ec87dafd068f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:31:58.438261
79dde716-01b4-430e-8e8a-984a1ebadaba	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:31:58.438282
1fb43c86-c08e-44c6-a88d-48feec2636fc	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1364}	2025-11-04 12:31:58.438378
259e64ce-6c69-43c9-9dd7-545e1a2d4b1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.6}	2025-11-04 12:32:08.452972
f9b9cc4d-7e44-429d-9377-3600641a0fa6	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.5}	2025-11-04 12:32:08.453036
086b8f31-6c96-4d51-87ff-d76d5c947b85	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:32:08.453057
87879b26-8d9f-415b-8fdb-9673c8cb44f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.1}	2025-11-04 12:32:08.453074
19b418f2-f630-4970-a247-8da592b685b8	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:08.45309
23649075-4ae5-411a-9d45-c1508f9ce99d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:08.453104
f93ce0c7-366a-4f80-868b-9c5878d147d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1374}	2025-11-04 12:32:08.453121
167d2f0e-6745-4b72-8b8a-e75982d4072a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.3}	2025-11-04 12:32:18.511168
3226520b-2da2-4dac-9c15-617a068f061c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.3}	2025-11-04 12:32:18.511305
704cac75-53aa-4c20-8768-92df63a764ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:32:18.51134
b89c3fc8-1ca6-4664-a822-96f3d61b7e73	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86.5}	2025-11-04 12:32:18.511366
9dea9911-2bd4-49bd-a9c4-393083e02258	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:18.511388
d989304c-2218-4fd5-8e32-9b87dfc0edbd	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:18.511409
a8319c2d-4385-44c0-beac-37d4edaf9dc1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1384}	2025-11-04 12:32:18.511433
3f16c889-5343-45ce-8185-47dcfd1e7d8b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-04 12:32:28.556513
9cca6ac9-8de1-4e9e-b0b1-741012c1fb5d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.8}	2025-11-04 12:32:28.556635
ac3cd972-73bc-4650-afba-5cfecd5e38c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:32:28.556669
9e3da674-c8d0-4547-91f6-fd1688e82403	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104}	2025-11-04 12:32:28.556697
ac63d296-5289-479e-93ab-4b0beebe89ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:28.556724
b05db1a5-f62b-4df0-8aa7-b6ff09714ba2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:28.556747
be4ccd28-6660-45b8-a086-7251b423f16e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1394}	2025-11-04 12:32:28.556773
0ba80b6e-f1e2-43af-b0d3-9dee4e16484d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.4}	2025-11-04 12:32:48.643743
9acd3893-3361-4af9-8e1c-f8c046adba1a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.7}	2025-11-04 12:32:48.643858
ff880e7a-d032-445a-8bf1-8bf0caae3576	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:32:48.643884
7752e67d-e3de-4ff8-9bfa-6b4e841985ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.3}	2025-11-04 12:32:48.643905
60afa003-b1de-45c6-a1d3-940068e16448	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:48.643929
0089fa36-fefe-43c9-9f3c-3a899662a84d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:48.643948
b366ff24-c202-43cd-9e5d-28dbcbb142c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1414}	2025-11-04 12:32:48.643967
2d55a77b-2f1f-4dd0-9fe7-dd8efe080f2d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.7}	2025-11-04 12:33:08.696515
1aaa05b5-0654-4596-a4ee-09285abccebc	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.7}	2025-11-04 12:33:08.696615
fc715661-b3fa-41f1-8564-cc322cd84668	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:33:08.696638
1cd0b2e0-b982-4ede-90aa-8a18af529b3b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.9}	2025-11-04 12:33:08.696656
e7abcaa0-285d-4ec0-a220-dedb14db97ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:08.696673
6c881033-3b68-46d9-9077-4c4990005378	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:08.696688
08b755a4-bc8e-4ba8-aa54-1eeda4953197	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1434}	2025-11-04 12:33:08.696703
586c30f3-f862-4e7f-94cd-759fd0eeb225	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.5}	2025-11-04 12:33:28.81304
ec918a82-9e83-4a70-ae97-fb4f4490d204	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.6}	2025-11-04 12:33:28.813161
d8996a76-0c6c-4837-8331-ed536887cef7	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:33:28.813196
c4895863-5c36-4514-a052-d86a0e3b13e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.3}	2025-11-04 12:33:28.813215
d722bf87-440b-4d02-afae-b252d98955ca	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:28.813232
9bc19778-8519-4334-9bf5-a5ece0171130	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:28.813248
424b7ecc-ff0f-4b98-a658-138d3600a4ff	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1454}	2025-11-04 12:33:28.813268
ace38455-352a-4a63-97a6-cd7638df98ce	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.6}	2025-11-04 12:33:48.892867
82607688-c276-4c23-977f-11ad538e4982	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.2}	2025-11-04 12:33:48.892995
8d57ef04-1eee-4421-aa11-79ff5dd081e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:33:48.893021
1e93488d-cf25-4234-ac92-fcb6579fb262	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.1}	2025-11-04 12:33:48.893043
d08064cb-7f7d-4ded-ade7-2fe92d4fdb2a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:48.893063
6fd1e479-cc75-4604-ab69-baca1a0743ee	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:48.893082
400f33b7-433f-466e-9d26-02830c3bfd06	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1474}	2025-11-04 12:33:48.8931
2aad7909-68f9-4559-af70-9b67e7688326	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.7}	2025-11-04 12:34:08.950128
22646a63-7c24-4899-9406-ea93b4a566f9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.9}	2025-11-04 12:34:08.950244
60719fbe-36f5-4177-9f84-8dbae0c95808	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:34:08.950278
df311131-6aab-4efe-a60e-2bcb71207162	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.3}	2025-11-04 12:34:08.950306
da5d3df5-3bfd-4030-8748-ce09da63ee9f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:08.950333
0a2062c9-ccc5-4c20-adfa-695a0f6dcf1b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:08.950366
c3d74323-1fb9-42c7-b580-b76ddcd2c410	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1494}	2025-11-04 12:34:08.950394
ce4a2128-e081-42d0-8248-de59a1401dec	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.1}	2025-11-04 12:34:39.068332
20a8fe39-b743-4966-a688-71efd9ef7368	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69}	2025-11-04 12:34:39.06846
b2971faf-1595-4ef9-9043-bcb5cf5a666e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:34:39.068494
f7ce8315-22f1-44e8-ae77-f0c3eb16e1cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.6}	2025-11-04 12:34:39.068521
ea599824-993a-41fc-8625-de464589cdb1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:39.068546
9352d60f-0a3b-413b-b059-12c209431d3f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:39.068568
852d3b1d-9f3f-4ddf-bf4c-7863c5c91d56	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1524}	2025-11-04 12:34:39.068591
9a75068b-7dd0-4cf6-8805-21655079b0bb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.4}	2025-11-07 03:25:48.903471
71230257-c8c1-430e-a941-563396fc9988	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.2}	2025-11-07 03:25:48.903527
71299def-c71d-4f84-ae56-8c8be0dc7be6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-07 03:25:48.903549
ff95641d-0e7f-4469-8ffd-7f15feadb81b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.3}	2025-11-07 03:25:48.903566
091dc85f-8803-4d9a-b6fb-3acf83bb1fa2	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:48.903582
607028c8-ed38-4dc0-bf1a-609b138d762e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:48.903598
286782fb-595c-4714-81d8-3cfc3bd06962	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 716}	2025-11-07 03:25:48.903614
8f66e12f-d803-45cb-b721-c6b9ad7323c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.5}	2025-11-07 03:26:39.149203
9c4a1e6a-ee39-4e90-89d8-292929f85bf3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.5}	2025-11-07 03:26:39.149263
aa0c9009-bae9-4ee2-b85f-9c0e2ab8c509	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:26:39.149286
969ab46f-841e-41e3-86ab-7813eacdb31a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.7}	2025-11-07 03:26:39.149305
46b1fd5a-1d96-470d-8424-116b06c81cdb	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:39.149321
5a7e8648-125b-4c75-bf41-775572bd3949	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:39.149336
35584846-ab76-4667-9780-d5e50d4e1296	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 766}	2025-11-07 03:26:39.149352
3a8925ef-c785-4679-86a7-dc191edbbf45	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-07 03:26:59.262476
80cb2f94-d29d-49cc-92ec-c632fdb028e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.9}	2025-11-07 03:26:59.262568
c61eb5ea-b045-454a-8a0e-910f45582490	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:26:59.26261
e7a3d324-b21c-44aa-827b-aef9acba3410	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.3}	2025-11-07 03:26:59.26264
50f0e940-5e71-4a2b-a91d-dbd160640162	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:59.262669
bf9781f7-1231-4bb5-94f1-577f262b3811	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:59.262695
d57cd76e-1f07-4c15-8e05-69d7dc8f0485	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 786}	2025-11-07 03:26:59.26272
59c7bf73-143c-4884-bd1e-901bdf259fee	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.9}	2025-11-07 03:27:19.327616
071261a3-83db-4975-81f1-61e682019e04	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.5}	2025-11-07 03:27:19.327701
7a824886-c868-48ad-95fa-353986f9899b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:27:19.327732
8ef70aff-7f58-4b3d-934f-203a9fa55ad1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30}	2025-11-04 12:32:38.573986
1de63bbf-25e2-4343-bc5a-753dc5dba1c7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.7}	2025-11-04 12:32:38.574105
ae32b426-21bb-4b27-bf68-e14ac3975600	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:32:38.574128
f8772658-fc3c-4696-890b-f03999ec123d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.3}	2025-11-04 12:32:38.574147
3766ef6b-7990-4886-91fe-621ff3ee3852	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:38.574164
4092464b-7e93-4020-aa13-c62159f517b1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:38.574195
baf68ff5-2b50-4037-9764-f5add3d009ab	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1404}	2025-11-04 12:32:38.574214
77f0bb9c-d109-4e92-a10b-53c6cff13b2a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.1}	2025-11-04 12:33:38.831718
bd04553b-cccd-42ed-8d2d-3922d2d8f516	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.1}	2025-11-04 12:33:38.831842
cf810462-17a0-470d-8819-70871411f28d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:33:38.831866
dce35421-6e95-403b-9b10-930491135a7c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.7}	2025-11-04 12:33:38.831885
56bca753-de81-44c4-a8da-29b9cd31acfa	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:38.831902
ac4ec922-4a9b-4efc-b028-9298968f5d7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:38.831919
800327a5-b5a6-4250-9a87-d978f4c77154	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1464}	2025-11-04 12:33:38.831936
b0dbcc1d-5eb4-4a04-9123-f1475349a539	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.6}	2025-11-04 12:34:59.177402
bce984dd-1846-4edf-b3f9-e9c52489001a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.2}	2025-11-04 12:34:59.177541
bec672df-d54a-4faa-b0d8-05e6db298b1f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:34:59.177576
530b2e83-ae0b-492f-8ede-f72b380c80cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.7}	2025-11-04 12:34:59.177602
1f980a4f-da83-4776-a31a-c1fafc15711c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:59.177632
fa48ca2e-550c-442e-a68a-55667b5c59b1	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:59.177659
7a07bd5c-fea1-49e0-9bd5-fb6b0f483d5b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1544}	2025-11-04 12:34:59.177685
ee256ef8-9205-4b61-bc0e-ebe693b06178	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.8}	2025-11-04 12:35:19.263489
f1bb3217-cd3b-4796-bcf7-9db941b82b29	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.1}	2025-11-04 12:35:19.2636
13b39cf8-e520-4eb6-9b06-3cf5c70f6248	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:35:19.263623
857ee721-6475-4794-813f-6627e91a1744	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.2}	2025-11-04 12:35:19.26364
68593986-b233-4744-9d03-b54cb2fefbca	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:19.263655
98ebe730-ac46-4193-81a9-b90dca0d438e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:19.26367
0e37a790-c63f-41a1-97c9-e3e4434fc421	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1564}	2025-11-04 12:35:19.263685
71d14037-2a7f-4d63-8365-ce2d64c81e21	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.9}	2025-11-07 03:25:58.976939
909da184-855c-47d8-9bc3-dce014eb832c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64}	2025-11-07 03:25:58.977081
6011ed6d-8336-48ed-af36-c096719542b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:25:58.977115
4f0c916b-9c14-4b0b-88e1-b3711d6c1e17	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.8}	2025-11-07 03:25:58.97714
c302fe1f-8507-45e4-b71f-3af9b10efb18	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:25:58.977162
1c8f1ad4-00bc-4bf6-affe-97afd84b275a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:25:58.977183
ce71211f-8b33-4184-a1cc-40f45bb85117	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 726}	2025-11-07 03:25:58.977204
3870809d-e204-4d7d-96bd-99f4eaea9447	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.7}	2025-11-07 03:26:19.041495
66091f86-2fd2-4d72-ad5d-eaf7216611cf	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.2}	2025-11-07 03:26:19.04156
4fd63429-cf51-4ad3-9595-0e9242617665	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:26:19.041585
7d9229e6-8ce0-48fb-8b92-efa7c1dd60bb	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.4}	2025-11-07 03:26:19.041604
ef83e70b-2b5a-4cfd-a7c3-f0b65fe8c2d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:19.041621
0c0d24f5-e64c-4fcf-9cac-e9a7b7de51e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:19.041638
5285989c-f729-46bf-a4fb-1c61938006d9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 746}	2025-11-07 03:26:19.041654
0a3b389d-012b-4758-9e20-a79edb576cd5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.4}	2025-11-07 03:27:09.309393
b54f3cde-5663-4cae-96d4-27066447e98c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75}	2025-11-07 03:27:09.309451
db20e4d3-457b-42dd-a7dc-ad51ce00b3c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-07 03:27:09.309473
e1766b9a-fc0e-41ce-a2e9-b4c4548a25b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.6}	2025-11-07 03:27:09.30949
29aa8bc9-b50d-485d-8279-36f948e5e96c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:09.309506
3d472d73-19d3-4708-adbe-b0f602563fa9	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:09.309521
0de40b68-75d3-49ee-9048-f5028183e369	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 796}	2025-11-07 03:27:09.309537
f5cd8b2c-b16f-46c8-a412-9d45eb076e10	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.9}	2025-11-07 03:27:29.389427
9ccb47ea-e5f3-4c63-91bf-108167b42e08	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.9}	2025-11-07 03:27:29.389491
fd517bce-4150-4ec3-a7a1-8f1aa3caa3f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:27:29.389514
feba900c-fdbb-4150-a25a-e542924fab6b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.9}	2025-11-07 03:27:29.389533
fa2a6a8f-9c50-4c98-9642-5e055a6b16d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:29.389549
c87e7173-840b-44db-8a6a-61f073fd3435	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:29.389566
bb92eae3-fd90-4b50-ab89-8786d6856c1d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 816}	2025-11-07 03:27:29.389583
a265b1a9-abf9-4785-add1-c9e691f16deb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.9}	2025-11-07 03:27:39.436905
287d1659-461e-4261-80e9-bfcf9befe623	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.4}	2025-11-07 03:27:39.436975
136ae7cb-632b-4866-9a47-b996a6ad4a39	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-07 03:27:39.436999
16d642e3-39a2-4504-beeb-22474bc955a7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.1}	2025-11-07 03:27:39.437018
c6e93902-676c-4b7a-bbe6-0640423924d0	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:39.437033
d7a26d9e-9afa-4a13-b154-1014e8061c9c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:39.437051
89534e81-6fe1-4b13-9b38-a532e1ba7526	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 826}	2025-11-07 03:27:39.437067
847c1537-26c3-4811-bd5f-2c31ac5664b3	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.4}	2025-11-07 03:27:59.523585
9370eabb-d087-4a37-9928-3a9cf3014619	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.5}	2025-11-07 03:27:59.523643
afe9457a-5912-4359-bdc2-a9bd573d1967	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-07 03:27:59.523665
3bbf38e7-3ca4-4d1b-ab3b-910ccd4373b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.5}	2025-11-07 03:27:59.523684
43197c1a-7916-4d45-ab5b-1681116895de	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:59.523699
9e6a9b8b-ce92-43c2-8765-3ba0cc6d26e5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.2}	2025-11-04 12:32:58.688166
38cd40a0-b358-401e-8d42-bb77f1bd2d45	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.5}	2025-11-04 12:32:58.688245
2db450e4-bbfb-44bd-987e-0cf35b64d036	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:32:58.68827
f1fd95cf-85c7-4266-8f22-666a50bcb812	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.7}	2025-11-04 12:32:58.688289
e9f1afe9-7a7d-4a86-8059-7e4cbbc35a35	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:32:58.688306
138fe4a7-a316-4b06-8984-a0f167baee9a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:32:58.68832
df275823-de55-42c6-800a-d2fc09ab9b9b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1424}	2025-11-04 12:32:58.688336
66e5dbda-3ce6-4bc1-bf5a-fafb9c723f2c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.2}	2025-11-04 12:33:18.759245
b2373dda-0f3c-45d7-b31f-18dcbe3997c5	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 76.2}	2025-11-04 12:33:18.759328
a3ceb028-0e9b-4af0-a303-71845a14523b	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:33:18.759356
b5b9ad59-6d98-4b4e-8b7a-e923ed0224a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.6}	2025-11-04 12:33:18.75938
cd6e8f39-b833-48fe-9c11-6cd82a4e7a90	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:18.759401
10ae78fa-cf97-40dc-8dea-09e09acd3d43	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:18.759423
b7df3278-09d8-455e-8e6b-62aad851651e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1444}	2025-11-04 12:33:18.759442
32c4864c-6975-4bdd-b35c-f18804c3875c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.3}	2025-11-04 12:33:58.934585
d5fc4257-fed5-4e9b-a8ef-98293b67c518	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67}	2025-11-04 12:33:58.934704
1e00eed1-61b7-49cf-82dc-acaf7bcf147a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:33:58.934726
27cfdd70-111b-43dc-b755-57cf23c35d5b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.4}	2025-11-04 12:33:58.934745
b51c5cbc-c74b-4a16-8b19-f7991006fcae	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:33:58.934764
7ac463cf-e95b-4ca3-aa86-f168d07b3c56	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:33:58.934781
68e0192b-c923-411a-86e0-fa321d98b4bc	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1484}	2025-11-04 12:33:58.934797
93da2523-8816-447e-afb7-ab4e3a143043	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-04 12:34:19.009478
32fe4b73-c88f-4f8f-9ce8-c8ce169b4788	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.3}	2025-11-04 12:34:19.009613
855e379b-9ba2-447c-a27d-6fab8494bd13	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:34:19.009639
ace5d52b-40b0-4a31-8481-3b1e70619afb	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.9}	2025-11-04 12:34:19.009661
916ddee8-cf7f-4fea-8fc7-f87330d076a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:19.00968
a15b67f7-a18d-4384-919c-fd2a72bd607a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:19.009698
f5455531-4faf-42e5-afbb-0e276eff77e1	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1504}	2025-11-04 12:34:19.009716
29e9917e-0162-4e98-b1e8-ad5529e5e87b	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.3}	2025-11-04 12:34:29.062219
19944c7a-b267-4ded-b80c-99eb43e01dd7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.5}	2025-11-04 12:34:29.062335
cc2b4438-a4f7-4b31-9799-17336ec26ae2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:34:29.062358
f40e4de3-b7ff-4010-81cb-7b42b3f5ad62	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.3}	2025-11-04 12:34:29.062377
f0d8a1e8-e62f-4f55-a4ca-531f64949a71	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:29.062394
c1d29efa-6360-4804-a06a-09060b07ad41	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:29.06241
a5016be2-a031-4a84-af09-29797df6a2ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1514}	2025-11-04 12:34:29.062426
ae2b6614-332b-4976-8984-dd63d6459260	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.6}	2025-11-04 12:34:49.135628
8519c3e1-445b-451d-945a-4ab0c13af785	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.5}	2025-11-04 12:34:49.135767
e39ff9c6-c957-4b27-a77b-be6bdbeb6e09	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:34:49.135803
d721ae8e-3602-4657-810b-d9f14ba7eb0f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 102}	2025-11-04 12:34:49.135835
ca4a468b-250a-4152-9056-c669ce6cf935	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:34:49.135863
42bda758-919c-4332-b653-cb128be7719f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:34:49.135893
2eb2159b-40ff-4e45-9cf3-83d489ad70fb	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1534}	2025-11-04 12:34:49.13593
76908b7d-9091-494e-8a10-9f7cbde7ab41	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.6}	2025-11-04 12:35:09.202098
de311d86-25b1-4bfd-89fe-fd36eb132a04	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.1}	2025-11-04 12:35:09.202183
4e480943-1e9b-48c4-9d38-cdbb2755177f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:35:09.202213
8a3124bf-5ff2-475d-b144-6d331fd3d021	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 87.7}	2025-11-04 12:35:09.202233
0cf04a3c-c17f-4b26-9731-71fa0e06e78e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:09.202251
41d89ea6-300d-49f1-8419-ba376927f85b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:09.202267
96e25acc-9546-4f95-9e30-44096d79a231	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1554}	2025-11-04 12:35:09.202283
13da59e4-62b3-49da-884c-9b3ecfaa0b17	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 25.8}	2025-11-04 12:35:29.300841
b444dc72-4cab-4c85-8d46-7aea4dfacfdb	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71.4}	2025-11-04 12:35:29.300911
5ede42d4-51c1-48d4-8708-aefa9d748187	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:35:29.300942
9170fb55-c4e9-428d-9e47-4910a066b383	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.4}	2025-11-04 12:35:29.300968
d9fca258-46a9-4095-b90b-141f2aceeafd	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:29.300991
48e31c1a-5f3e-4de3-8db1-0ab1269fd3db	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:29.301012
8f5affe8-47f0-44c7-982b-b5ac31000682	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1574}	2025-11-04 12:35:29.301032
8d087321-b095-494a-bdd5-2db2b87fa2ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.9}	2025-11-04 12:35:39.316967
4aefb3e6-ef7c-4492-84a6-c12c5b111b5b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.3}	2025-11-04 12:35:39.317037
e73d6882-8c79-44c7-acdd-76e8fe62eeaa	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:35:39.317059
24fa41e0-42e1-4a7d-a4bb-c47a7d0ffa54	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.4}	2025-11-04 12:35:39.317078
3f8ed311-0414-4c71-b1a7-1a81cd85260c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:39.317094
291a05b6-5f19-4bd8-bca9-83f8453f6ceb	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:39.317109
f5783c50-8f03-4211-b745-ef545bfbc853	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1585}	2025-11-04 12:35:39.317123
17e3333d-881b-4945-9b18-91828b1c22e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.2}	2025-11-04 12:35:49.368456
03f3b151-a3fb-413b-a561-06d03e5b6d6a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.8}	2025-11-04 12:35:49.368527
00ea02dd-b0a0-4d6c-a72b-4317ee086a93	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:35:49.368551
3a72e866-2721-4b4b-9214-53f509b7e0c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.1}	2025-11-04 12:35:49.368571
045bd65f-08c5-4eee-a97e-8c6621b6302c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:49.368593
3ee4444a-33f8-4fbd-a209-12c5b46a3e2d	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:49.368622
c70c5393-2ef2-4879-8257-2aa7f90f29ab	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1595}	2025-11-04 12:35:49.36865
924a0e71-14ec-4768-bba8-9bb100bca926	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.2}	2025-11-04 12:35:59.411199
95f53a9b-ba0e-45d3-afe1-13cb126049e2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.2}	2025-11-04 12:35:59.41135
efe7d359-6bbd-4897-a9d7-dcd51286e683	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:35:59.411382
4a77edbf-98bf-4889-865a-f22df6b09854	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.3}	2025-11-04 12:35:59.411407
e8452668-0e92-400d-91d1-ce9dc9fbca1f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:35:59.411431
f6b45160-7bb9-4586-8579-4405cd9fa313	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:35:59.411464
0b4e1eac-910e-4925-92ce-76757f2494e3	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1605}	2025-11-04 12:35:59.411495
d5272df7-ce6e-4dfc-bfb3-055f58b3e4b6	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27}	2025-11-04 12:36:09.424853
13412196-f7d9-453d-9d0a-658494ba4905	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.7}	2025-11-04 12:36:09.424945
d7aa9318-66eb-4437-b153-48c734067377	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.33}	2025-11-04 12:36:09.42498
f22c489b-d4ee-479b-8b4c-aba3606de771	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.2}	2025-11-04 12:36:09.425006
1f22c8f5-1c51-44a6-8e05-94a1475875cd	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:09.425029
7d00af54-191e-4ee7-9281-a8902047070a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:09.425051
f23b49b9-c8df-4c8d-85c9-3b239127f69b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1615}	2025-11-04 12:36:09.425074
88173f3f-c42f-4b58-88af-4c92639578dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.5}	2025-11-04 12:36:19.491138
2b400615-e7e8-47f6-9c96-cad6949990f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.9}	2025-11-04 12:36:19.491248
4144c3a2-9eed-413a-9bf9-57c5331e1cbb	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:36:19.491282
951ffe2f-ce33-47b4-96ad-0ecd430a44fc	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.3}	2025-11-04 12:36:19.491307
58f7c697-623f-4337-bd24-fde26d65bb43	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:19.491332
768a10fb-8658-4a26-b092-a4debbfea509	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:19.491355
e5e2cfe9-2e39-46cf-97bb-3505e2001da9	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1625}	2025-11-04 12:36:19.491376
5b77c0a2-2272-4373-af59-e934fc207f61	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.4}	2025-11-04 12:36:29.532872
7ae045b3-b7a8-456b-9665-b80d7ba3fdff	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.8}	2025-11-04 12:36:29.532955
25dcec53-9ec8-4dc4-a139-f5f47dae2751	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:36:29.532994
e32560a5-a4c5-48b0-89e6-1a947d9ccf05	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.7}	2025-11-04 12:36:29.533029
206b2afb-3654-49f0-849d-f6581120c6dd	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:29.533053
6ecdb5c4-0103-4880-b624-062a2d07622a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:29.533072
5a919e47-b6aa-4de3-a3a8-cf0a208fbbe4	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1635}	2025-11-04 12:36:29.533092
f802083f-e832-4da2-ad83-24acc3c58d19	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.7}	2025-11-04 12:36:49.605879
896ce0dc-0a17-44bb-a608-34245c6b23f8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.8}	2025-11-04 12:36:49.605948
c22afd8f-c7c7-449a-9adf-0e0e8719831e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:36:49.605975
3316a7dd-4eeb-412a-8ccd-7e7e1a8bb790	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.7}	2025-11-04 12:36:49.606005
ca8c8b3a-f76b-4d99-b2d8-2eae62c9153d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:49.606027
38ab297e-dc33-42b1-9986-7773a016a42e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:49.606048
2563dbf5-dede-4255-91aa-29f25436bae7	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1655}	2025-11-04 12:36:49.606067
9fe0a3de-61e5-4f24-8e3b-25443b856c17	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.4}	2025-11-04 12:36:59.646798
9f2a904b-cf04-4e6d-b0a1-eb93dae9db82	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 62.9}	2025-11-04 12:36:59.646885
7166e225-8688-409c-88b7-9f3862f87d1d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:36:59.646915
fa3d72d5-1eb3-4249-9543-57cc4efd54e9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.9}	2025-11-04 12:36:59.646939
b2156b55-51cc-43e3-ba8e-ff0bda4033ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:59.646964
3f4c9493-9ef5-4fa1-a72b-98bab598960e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:59.646985
1561fc81-e3c7-42df-9bce-1449c7cffad4	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1665}	2025-11-04 12:36:59.647007
05698a79-d4c6-4792-af27-40d039339411	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.3}	2025-11-04 12:37:09.666979
5b1db378-befa-48b3-b512-155abde70ea3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.1}	2025-11-04 12:37:09.667061
463636df-83f8-493b-a949-a3b6b6bbda51	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:37:09.66709
8147499b-e2a0-4ffd-9304-584adc139963	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.8}	2025-11-04 12:37:09.66711
6e710b22-cc5e-49a5-b3ce-95f8b7a7d6a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:09.667127
ea82abe8-aa67-46c9-a403-7b7650f186f7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:09.667143
a01a8d4b-bb1f-48ce-aaf8-601dbac7205c	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1675}	2025-11-04 12:37:09.66716
842fffeb-faec-4376-a608-19c806528ec2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.4}	2025-11-04 12:37:19.729937
b4b1e183-2a4e-4cff-9704-457ed6d1c24d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.9}	2025-11-04 12:37:19.730009
2792a087-3ac4-49cc-87d1-4fdcd32784c1	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:37:19.730035
a79e56c9-5f37-4db2-abac-1914c45bbba7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 88.2}	2025-11-04 12:37:19.730056
130e3f72-5037-4c0a-8898-9f1291366b81	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:19.730076
ceffa3fd-0e9b-4374-866c-fa9f43436001	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:19.730094
d239e45b-d1a1-4cc2-9b1f-cead287c157e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1685}	2025-11-04 12:37:19.730111
17146d96-dbcf-41da-aa8a-bc1637b893d4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31}	2025-11-04 12:37:29.76422
db10d5dc-ea6c-4243-8035-891596de2bd2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.2}	2025-11-04 12:37:29.764306
f230d798-1d2d-4b11-a505-ff2ad9098796	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:37:29.764336
dd1d289b-5f3e-47d1-bba3-55b6df4f4f48	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.5}	2025-11-04 12:37:29.764361
ab933ea7-9400-4a6c-b0c7-91b7d69dd0ba	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:29.764383
8b57f5a7-cdc8-4db4-a5f1-42455fa695d6	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:29.764404
0cb87c11-8e8f-4b7b-a2b1-25058efd1bd4	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1695}	2025-11-04 12:37:29.764426
b8a2bf58-a23a-447f-9119-dc66b28b7c8f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.3}	2025-11-04 12:37:49.844985
6a762b46-e2c1-4004-a77a-f9fa0dc4c984	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.7}	2025-11-04 12:37:49.84505
1a094318-2acf-47ca-9f5d-a9012a9feee2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:37:49.845072
c8746c85-9ee3-4ebb-8df9-26e090f6a94a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.3}	2025-11-04 12:36:39.548827
6ddd25c4-b3c5-4af2-bef5-abf458ef5f25	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.4}	2025-11-04 12:36:39.548914
e8297804-4de2-4084-9b2a-b7f1444607b6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:36:39.548948
06f7da00-ff59-478c-8d6b-9c3458db8686	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.6}	2025-11-04 12:36:39.548976
bf60e0f0-a022-48b1-962e-5be8c4614cb0	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:36:39.548998
d40bfa5f-d41f-4f5d-9602-f54a54763a6e	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:36:39.549026
8b7d119c-68c9-46d2-a55d-767770caa29a	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1645}	2025-11-04 12:36:39.549049
605c4d86-2fe2-4093-a811-200e9f2e50a5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.8}	2025-11-04 12:37:39.774802
dcd74562-4c62-432f-964b-5162000c4137	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.9}	2025-11-04 12:37:39.774887
b3a11b0b-6e58-46d1-ae22-c3e0dda751c6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:37:39.77491
39e13b7b-bfc3-46bc-beb9-04701bba1a16	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.9}	2025-11-04 12:37:39.774928
117ebfe8-5299-4c57-87f9-952ced3f54bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:39.774944
f38b6f75-b2ac-49b9-ab4b-14b3fc59d9b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:39.774958
79829ec4-21fe-43dc-bda6-077be9e47222	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1705}	2025-11-04 12:37:39.774973
88501d6a-2f30-4cfc-b6c3-93c951703e64	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.1}	2025-11-04 12:39:00.073412
007530e8-205a-4188-a218-42a72bd71345	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 68.3}	2025-11-04 12:39:00.073544
ed4c34f3-f40e-4a55-a51e-7d994128faa4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:39:00.073581
8479c0b7-20e3-4b91-917e-4c75e168edd3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.6}	2025-11-04 12:39:00.07361
01fa0770-790e-4fe6-b386-ee367c1523be	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:00.073641
c0bcb3ea-2597-4559-89d4-acd44c8d6984	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:00.073665
bbbba9c3-769a-4b25-a04e-7bc3d2dfdb7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1785}	2025-11-04 12:39:00.073687
5e7c0c6b-1a86-453d-a93f-658cfc0d7714	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31}	2025-11-04 12:39:20.184192
8ca1faf6-fa16-477f-927d-fefbbfd7eed9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 73.1}	2025-11-04 12:39:20.184259
c3c2c370-7afb-41aa-9f17-e3ed881d91c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:39:20.184285
231a73a3-47e9-44af-a5d0-45a44f9afe71	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98}	2025-11-04 12:39:20.184306
c557949f-315c-41c5-9ef1-0a5eb5a94751	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:20.184324
5cb87cd1-079d-4cba-a108-d1098768d836	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:20.184342
18bb67ae-19e4-4952-82f4-461697a2c2aa	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1805}	2025-11-04 12:39:20.18436
a0840496-465a-4724-b1df-e529447836d7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:40:00.320515
2023fb4e-94dd-4a7d-84c9-111633c7d86d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.5}	2025-11-04 12:40:00.320578
940f7e94-956a-4fad-b1f7-05119f2f3551	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.39}	2025-11-04 12:40:00.320603
552049ff-f20a-4589-a96a-27180794c17b	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 98.8}	2025-11-04 12:40:00.320623
89cc7803-ac0b-4c4a-8529-4590e8368dd8	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:00.320644
daf4893b-c875-462c-a4ff-7c2cb0b429a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:00.320663
452e2e68-8b45-41bf-8f45-1b22353b8dfd	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1846}	2025-11-04 12:40:00.320683
85006c4e-c1ca-4440-81d2-22d3726848c1	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 29.4}	2025-11-04 12:40:20.434734
5533aed9-5dd1-4a8a-8b9d-50bcdd028bf8	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.1}	2025-11-04 12:40:20.434816
0a3e15ef-3158-4314-bf6f-4fdb06ef0d85	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:40:20.434855
ae18d9b5-966d-49ee-9ee3-e4b35a0a1b3a	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.7}	2025-11-04 12:40:20.434887
13c4924f-acdc-4ed2-8df3-112061caaa3e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:20.434914
0ec5abba-3278-4c4b-990f-9f06c19a9994	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:20.434939
8eec0f4f-3511-409e-80ec-5d4b52d4da09	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1866}	2025-11-04 12:40:20.434963
104332b3-7b5e-421a-aeea-ea6c444801aa	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.8}	2025-11-07 03:26:09.024227
1ea36054-c23b-476d-818d-11f0f6527ccf	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 79.2}	2025-11-07 03:26:09.024293
fb7eb651-f97f-4cec-b00d-22de4e5a85e8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:26:09.024314
d3d62fad-4ffe-4f31-8e23-8e6e5ccb96b6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 93.4}	2025-11-07 03:26:09.024332
e6975855-20c0-4445-b184-ece8d23bb220	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:09.024348
95cc605d-fa7b-46f0-9c4e-916b70290640	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:09.024364
ab2ed532-0520-4082-a973-84312d19bb4d	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 736}	2025-11-07 03:26:09.024378
60958de7-24db-4ec0-9fd9-5305b9085a07	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.4}	2025-11-07 03:26:29.093567
2c4144a2-e6cf-4acd-b500-2af0a2f403a7	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.3}	2025-11-07 03:26:29.093628
e673723c-bba7-4649-9c0b-aaa71dcab1ff	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:26:29.09365
ba9bd18a-5406-4423-a6f3-010cfcbbec66	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.1}	2025-11-07 03:26:29.093669
b887c845-3ae2-4358-8c4b-87cfd74b07c3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:29.093685
d910ad04-7654-4b39-9d75-81f9e23d7d7a	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:29.093701
c21d7460-1c90-4b1e-8c8d-27ab37efb5ae	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 756}	2025-11-07 03:26:29.093716
295e9cab-dd8b-4560-b18c-0f43120a0f74	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.4}	2025-11-07 03:26:49.174444
ffa75bdc-5fd3-41de-82f0-c408d45afd95	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 66.3}	2025-11-07 03:26:49.174506
bba952e0-950a-42da-b499-35573dd0b180	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-07 03:26:49.17453
857ae54f-fba2-4f54-a917-0959353196f1	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.3}	2025-11-07 03:26:49.174548
2d7ca421-9c5f-4595-86fa-59eb1a1d7881	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:26:49.174564
4d8a6db9-465e-4055-8be7-b9c1e161d5dd	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:26:49.174579
2f886511-4d26-4ac7-8c1b-723c0f6ad436	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 776}	2025-11-07 03:26:49.174594
f52c78c0-f8b0-45e6-b70c-e4ee6849375c	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.4}	2025-11-07 03:28:09.566655
39d18a4c-ee09-4a4f-a29a-94fe785c245b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 71}	2025-11-07 03:28:09.566751
e5a99243-cea6-4684-9fc7-a204e180b427	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-07 03:28:09.566776
cc4048a8-fef7-4d6f-98f0-8ba429f8fadc	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.4}	2025-11-07 03:28:09.566796
83b67bc6-5670-406f-868a-88798f69f4e7	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:28:09.566813
1a23ac0b-fef1-4267-a11d-df0d46968d65	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.8}	2025-11-04 12:37:49.84509
09394091-b4f9-4d60-b79f-e8d53c8d8a10	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:49.845106
a99b532d-2fd3-42ca-9a95-380576ecfa39	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:49.845121
ae4368ae-f9ba-4c2f-a17a-c048b487c607	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1715}	2025-11-04 12:37:49.845136
0e21c202-94b5-48bd-bcce-884225d2a5cc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 35.3}	2025-11-04 12:38:09.91209
ee2eeb65-b70b-4823-94b0-db78654596b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.8}	2025-11-04 12:38:09.912183
66e7e5f2-3a79-4cde-a938-09887cc773c6	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:38:09.912207
ba23b38e-7f09-4cbb-ad34-060c75a530ac	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.1}	2025-11-04 12:38:09.912223
7bf10d98-d10c-4fd9-976f-abeb26bec416	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:38:09.912244
3bd57081-6789-4ae6-8137-a8be33479bbd	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:38:09.912267
985c11be-976e-4d7c-8171-dc84ff57ac4b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1735}	2025-11-04 12:38:09.912292
507e469a-5fa8-47fc-9c71-447409688d94	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.8}	2025-11-04 12:38:40.01244
3f187ee1-b7ef-478d-a213-2f417475417c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.6}	2025-11-04 12:38:40.012558
ef6d930f-329d-45ce-91ae-33e40cafc300	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:38:40.01258
5f35f664-7f59-4f90-a7e3-dc7eb33577e7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 97.2}	2025-11-04 12:38:40.012597
01e14594-eba4-4f35-a9e0-be514268fe09	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:38:40.012613
e4564bea-1e75-4e4c-b1c8-56e321bbe6f9	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:38:40.012628
b67940dc-b9f1-4871-bee2-6f0da2d5d841	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1765}	2025-11-04 12:38:40.012652
aeb44a21-5698-4668-b229-1415523cca7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.2}	2025-11-04 12:39:40.254168
386a4a9b-9684-4ed1-af9c-128c6581eac0	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.6}	2025-11-04 12:39:40.254249
63332eaf-b104-4502-8c1d-9ee21b430861	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:39:40.254271
f6f317f0-3c83-4f1b-a048-2d5a2e286a7f	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 90.4}	2025-11-04 12:39:40.254288
e7f71658-cd8b-4c42-a041-849b3720c0a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:40.254302
86145a17-50de-4d28-833f-9fc7b117cbe0	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:40.254316
252f1c67-5181-4a05-b15d-c9eee6355a06	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1825}	2025-11-04 12:39:40.25433
c0384b01-71dd-47be-ad8b-0161bd26ba8c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89}	2025-11-07 03:27:19.327757
4489a1e9-4ae4-4c24-b8b8-fef9db5963bf	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:19.327781
288150c5-4cce-4f8c-8b70-0de0408fd6c8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:19.327807
37d7ce12-9953-4ec0-86f5-428ef811d057	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 806}	2025-11-07 03:27:19.32783
9399883d-b7e1-406b-a20f-9ed24f11b720	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.6}	2025-11-07 03:27:49.44955
f09fb848-a40a-4fa2-a93c-e43331a1dbfe	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 72.4}	2025-11-07 03:27:49.449607
f154b0ee-aa41-4d06-a24b-6f98acd43655	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-07 03:27:49.44963
f7c97243-d40d-4769-b6ca-badd315102dd	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.8}	2025-11-07 03:27:49.449648
49d5907f-ea75-4b15-a714-ca4f43d2c5a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:27:49.449665
f6373836-8c39-4e86-a5af-ab9bda18e1e8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:49.449679
8411fba3-df7a-4db4-a563-8946ba20edd6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 836}	2025-11-07 03:27:49.449694
d0b089ec-edf1-43c2-a710-e07b9539722d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.7}	2025-11-04 12:37:59.879039
34d22549-079f-4340-b880-d2ec9e7fe8a3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.8}	2025-11-04 12:37:59.879141
12ea6c14-d8b7-46b6-9ba8-b74375b34ef8	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:37:59.879188
ce4ecb6d-ca29-49e9-9b48-e8f90207de1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.1}	2025-11-04 12:37:59.879216
3025237c-4b0a-4086-9e63-ce735294f476	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:37:59.879237
ec933966-4fc7-4a4b-a3f9-edeae8ee3e5f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:37:59.87926
b2c4fe5e-9628-4fb4-bee0-046d05a9b461	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1725}	2025-11-04 12:37:59.879281
188a227f-20f5-4c0b-ad01-23b2c01f1ecb	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30}	2025-11-04 12:38:19.936718
98db2b1a-1f23-498c-ac4d-723e614b4d62	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.7}	2025-11-04 12:38:19.936781
0f9421d2-28ce-4613-b9cf-45b3fe099391	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:38:19.936802
88c8fcd3-c4a2-4d65-b702-9490e3c48450	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.1}	2025-11-04 12:38:19.936818
506caec7-5c14-4c60-abf7-00691372c8b9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:38:19.936833
5dcffc31-39dd-480d-b310-963df3811bea	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:38:19.936848
565d68a1-00e5-48d7-b3b7-e3385c6d1f73	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1745}	2025-11-04 12:38:19.936862
94a53981-4696-4757-b5d4-a8c51ee5ae96	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.2}	2025-11-04 12:38:29.949971
ee63dbbb-4365-4bc8-8595-6b9bbc24c093	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70}	2025-11-04 12:38:29.950034
423dc3ed-f67a-4095-86df-fc75f6f7379a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:38:29.950058
eca31984-0333-4516-9221-90cc09bb1986	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.1}	2025-11-04 12:38:29.950077
2eea777b-e9c4-4c34-a293-088043b26c24	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:38:29.950097
43d6366b-9328-479f-8443-f7d1fc24813f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:38:29.950115
54e87e07-f7ee-42b4-8c93-18388e681859	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1755}	2025-11-04 12:38:29.950135
e239fa5d-9584-45ae-b2fb-595093c2e1dd	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.4}	2025-11-04 12:38:50.066066
847d22c8-1572-46b2-9ae7-bc11a56725c2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.8}	2025-11-04 12:38:50.066148
046a6302-d8a6-4b4b-92d1-3d7c52bdffcf	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:38:50.066188
cf109632-a308-49dd-928c-e187495338d9	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.6}	2025-11-04 12:38:50.066213
f84cfe94-e62c-42b4-bb3d-4ced11e92c6d	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:38:50.066236
578d3a68-d058-4af1-9297-4f4943c8781f	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:38:50.066258
ad3ab735-c743-45c4-b0e4-443e71800371	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1775}	2025-11-04 12:38:50.066278
0579135b-1045-49e4-860d-bd233ff599d5	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31.4}	2025-11-04 12:39:10.125106
06bb5b2b-0ec4-4ed6-ac3d-18c158267a7a	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 74.2}	2025-11-04 12:39:10.125219
40ef768e-bb85-415d-be61-e3ff76c2333a	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:39:10.125255
ee5d46d9-53fe-4852-88a6-ce0a3547a1f3	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103.5}	2025-11-04 12:39:10.12528
d4f75a49-28ab-49a4-b8df-b35d76cd1e8f	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:10.125303
bfe98561-af24-4f89-9b86-019cbe9dd6d2	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:10.125322
9d8f4fa3-188e-4884-971a-c6bc20f84826	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1795}	2025-11-04 12:39:10.125339
12dc73ef-ab0a-4bdf-86d8-76392ab22160	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.4}	2025-11-04 12:39:30.188423
0ba1315e-3681-401f-a386-f0c5d398f1a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.1}	2025-11-04 12:39:30.188497
7d1db2e4-de02-4f37-989b-f5386c46633d	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:39:30.188523
5cb4a313-5a24-45cf-8e96-e22d45cc83b2	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96}	2025-11-04 12:39:30.188542
6c087036-811a-4c1e-b077-439a7f8e8a92	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:30.188563
48e2e1c7-3587-4cb3-bdee-1e255f2e1012	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:30.188582
4f2d497c-9994-445c-8c68-e1bd12384580	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1815}	2025-11-04 12:39:30.188601
0b9086f6-98bb-4e8c-a18f-8a3e7bd4b07f	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30}	2025-11-04 12:39:50.306368
020543d0-4efc-4215-8a02-ca577f4c2901	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78}	2025-11-04 12:39:50.306459
59a9cd2e-4269-46d0-bc30-8e423b74682f	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:39:50.306498
4288cdf0-e584-46a5-9203-b0a5734f1e53	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.9}	2025-11-04 12:39:50.306526
3ee9acc3-1f9e-4420-a5cb-68291a0d06fe	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:39:50.306567
d818cb49-1a4e-4dd4-83ec-8322d590a3a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:39:50.306607
23992e9d-0717-41fd-9dbd-3333faced338	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1836}	2025-11-04 12:39:50.30664
75b9141a-33bf-4480-befc-42fe0abf39e7	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 32.7}	2025-11-04 12:40:10.375984
557fefc1-58d4-4a27-8632-47068f1ee407	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.6}	2025-11-04 12:40:10.376051
616e1da3-458b-48a5-8354-b39f1dd3db95	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:40:10.376072
e0b6cda7-bdb4-4e78-a156-dceda37d8dee	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.8}	2025-11-04 12:40:10.376088
8282a165-acb6-4629-b27f-d2f449b447f9	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:10.376103
1cf0e4d9-9f3b-4a4a-9fdb-03ba03d30147	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:10.376118
3017f8b3-1bd7-4873-97cc-e65f251acf67	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1856}	2025-11-04 12:40:10.376134
eae41175-5089-4134-8f6d-0f92a55d8b83	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.1}	2025-11-04 12:40:30.443637
ffd065bd-a67b-4fb2-aa25-800d3eeec069	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 60.5}	2025-11-04 12:40:30.443746
9ad09ab4-d920-4622-8a2e-94f50982a20e	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:40:30.443774
6f197a1c-90f9-4bec-b664-c683b8d96e69	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 95.9}	2025-11-04 12:40:30.443796
6f6bbb25-7221-42e9-b783-540be32cec9a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:30.443816
64989c49-631c-4a5d-8c50-932d1c520cfc	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:30.443837
efd8cd45-33b0-4448-8405-5228ec573f9f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1876}	2025-11-04 12:40:30.443858
7ab11269-61e9-4d19-8580-59d398cc393a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.3}	2025-11-04 12:40:40.503306
d508fc5b-094f-4fb6-9932-b50bcf09c6d3	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70.7}	2025-11-04 12:40:40.503378
b6cae94e-943f-4f48-ab7a-1392adb5af85	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.31}	2025-11-04 12:40:40.503406
5d56f8a3-ada2-49e6-8223-e253186c335e	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 89.7}	2025-11-04 12:40:40.503428
c35adf41-ce5b-4058-816c-2e67889cad0e	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:40.50345
322eb6ee-b6d6-4f45-b17b-0f398988943b	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:40.50347
ca2f8cb1-4f76-4f08-8755-dc753a0d5b17	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1886}	2025-11-04 12:40:40.503489
d5864fbb-f681-4740-8252-3553e2899fed	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 28.8}	2025-11-04 12:40:50.561136
28395c9d-3c0e-442c-969d-87be2a360968	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 77.2}	2025-11-04 12:40:50.561248
120dcde6-4783-4ea9-b72a-887fa5cead83	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.35}	2025-11-04 12:40:50.561276
2145cc89-039c-4141-a26e-260685c49536	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 86}	2025-11-04 12:40:50.561299
02f706ac-ec35-466d-b6fd-2222dd980f2a	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:40:50.56132
01740081-5dcd-4fe7-8cec-35f18c5d56f7	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:40:50.561339
7929d827-3908-41dc-b298-aae4a546000b	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1896}	2025-11-04 12:40:50.561358
ecc3619b-3e2c-4606-855d-9163502a60f0	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27.6}	2025-11-04 12:41:00.569214
3e9c7218-f8e8-429c-94a4-c1e39d930183	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 75.1}	2025-11-04 12:41:00.569279
0ce04ce0-38ab-4b63-aafa-ef75c85c2694	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:41:00.5693
7fcaf39e-86dc-4196-9b42-dcd9899fb7be	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 104.5}	2025-11-04 12:41:00.569317
6310293c-767e-4217-8c73-f026802dc9ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:00.569333
c988f4df-fb25-471b-8576-fa3282a3d2cc	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:00.569349
d16f7eb0-ae2a-4968-bc86-85832f8a8e71	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1906}	2025-11-04 12:41:00.569364
38d8e260-c348-4f15-8b20-b2675c84ee67	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.6}	2025-11-04 12:41:10.629417
6f74edea-8564-44aa-9e3a-12193054a19d	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 65.6}	2025-11-04 12:41:10.629502
2d8da8ca-cf96-4adc-93d1-3171ce9b1728	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.32}	2025-11-04 12:41:10.629543
3b3e5bd0-8d6b-4673-8972-4feb82eb1348	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 91.5}	2025-11-04 12:41:10.629576
a361d38b-9db0-44ee-97c6-6d070bfe9dd3	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:10.629607
2a7aadeb-48c9-4e87-a260-afb466ea9da8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:10.629636
5e3e22c3-be9d-43df-a47b-fd980df29d1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1916}	2025-11-04 12:41:10.62967
239a41ca-f482-4efc-8b42-f17937a201e8	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30}	2025-11-04 12:41:20.686133
7c8af35b-771e-42ff-9a46-3af4f487043b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.7}	2025-11-04 12:41:20.686207
22599df3-4303-4816-9809-7410f8d764dc	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:41:20.686228
1c8f538f-1e77-47eb-974f-1f7be314cea7	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 99.1}	2025-11-04 12:41:20.686244
5b476e80-01b6-4e67-bf2e-1a096fbc6899	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:20.686258
1b0d6ea1-7666-4158-bec0-462d92dd64a8	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:20.686272
f2c9a06a-a605-4974-a976-a81e37d86a53	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1926}	2025-11-04 12:41:20.686286
5f79f85a-6e92-4fa2-b243-4085f07671b4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 34.4}	2025-11-04 12:41:30.698715
56da95c3-39ab-4d9b-8506-da351a01916b	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 70}	2025-11-04 12:41:30.698776
3781977f-34d0-4357-a39b-aba92d37a359	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:41:30.698797
f61b6d9c-7f5a-46fc-93fd-c36ded9935a4	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 92.4}	2025-11-04 12:41:30.698813
de887e99-6951-42cf-bff6-2d29f2af589c	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:30.69883
ec7a1bff-04cf-4464-b7c3-1faf4fd92ba4	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:30.698844
0833d347-57f4-421f-927c-e5f83751db1e	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1936}	2025-11-04 12:41:30.698858
9fd773a9-6ed6-42e1-9e65-eac54a758eb2	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 27}	2025-11-04 12:41:40.752997
c9c9675c-093f-4eff-9739-6ecfbac3be5e	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 61.8}	2025-11-04 12:41:40.753065
5b00b87b-cda7-43ba-a04e-8e89e0f5fa29	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.38}	2025-11-04 12:41:40.753088
eb692058-25e6-4cf4-884e-ad7229bea3a6	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 100.8}	2025-11-04 12:41:40.753105
3509789d-875f-49eb-b89e-a295959655a1	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:40.753122
24b7ba16-d0da-4404-934f-6b477528b574	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:40.753138
c173db50-db9d-4ca5-93fa-194830628ccf	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1946}	2025-11-04 12:41:40.753154
4ff0a89e-c456-4b6d-aaf0-30b2dcac3663	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 30.1}	2025-11-04 12:41:50.811117
8954200b-2ca5-480f-883d-dde675449499	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 78.1}	2025-11-04 12:41:50.811203
35113d84-3496-4264-9946-e23902c967a2	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.34}	2025-11-04 12:41:50.811229
e83b4195-3980-4cda-9126-19f0b11d00ad	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 94.1}	2025-11-04 12:41:50.811251
518bfbe5-e9d9-4eaf-8808-7b7f240659ec	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:41:50.811269
e5b7dbaa-c2ed-463b-bda4-069701ecfbda	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:41:50.811287
17dab56d-ff96-45c8-8cfa-d608e8d07ea5	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1956}	2025-11-04 12:41:50.811304
d84ed131-38d0-44a0-83d7-8f2e09be3f5a	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.7}	2025-11-04 12:42:00.820038
01ab3f3c-7262-4c5e-bcf4-73a87045971c	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 63.6}	2025-11-04 12:42:00.820107
55a9e0db-0c6d-46c4-8650-cdd67575caf4	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.36}	2025-11-04 12:42:00.820129
a2113187-95c6-494f-8d6a-9487b21df760	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 96.5}	2025-11-04 12:42:00.820147
3cfff88a-cdf3-469b-9262-31c210ba67a5	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:00.820163
cc4d4e43-55a1-4f8a-8ab2-1c763e777a11	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:00.820192
bf116f52-58a2-4dcf-89cd-4f7210b0e9eb	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1966}	2025-11-04 12:42:00.820208
f1b7a3e2-975b-4456-89e6-01bdb2a0421d	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 31}	2025-11-04 12:42:10.876319
24b8de6c-1c92-42f0-8dbf-38852d7fab64	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 67.8}	2025-11-04 12:42:10.876389
0c46f69d-7471-40ca-abd5-668cba2d6557	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.37}	2025-11-04 12:42:10.876411
c43cbb9e-1225-4293-8883-8aeb5ce7909c	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 103}	2025-11-04 12:42:10.876428
0e8e2421-324d-49d1-a490-610d65af2629	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:10.876444
8f087259-3b2b-4121-ba95-705519d96225	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:10.876458
d5b6574f-76c6-4253-8347-3aaa37be303a	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1976}	2025-11-04 12:42:10.876473
e5d1cc3e-6e8b-42d3-9dac-522a5edf37e4	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 26.4}	2025-11-04 12:42:20.928967
772c545f-09d8-47ec-936a-463cfb42bcef	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 64.4}	2025-11-04 12:42:20.929043
7cef7393-4f0e-4026-b473-f099e16cc8a9	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-04 12:42:20.929071
a4262061-7ed9-4e11-8d90-83571913fd6d	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 101.2}	2025-11-04 12:42:20.929093
ecf1bbf3-6344-4299-ba0f-bba4f8d1e2e6	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-04 12:42:20.929116
c4ed2a10-9635-43b2-a480-f2a82a3a801c	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-04 12:42:20.929137
87801533-798f-4802-8394-7328b0250a85	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 1986}	2025-11-04 12:42:20.929157
ece00406-e644-4b4e-b775-2ce9b9e8d098	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:27:59.523714
04ef07fa-4a36-46ae-88f0-139e3f32b7b6	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 846}	2025-11-07 03:27:59.523728
389432ff-9664-4f9c-bc74-0cdd897f5acc	8697991c-4de3-4a5c-9961-ba73acfb61f4	temperature	{"value": 33.6}	2025-11-07 03:28:19.586926
c656bc57-39ba-4ef1-9e82-c6e041cffac9	8697991c-4de3-4a5c-9961-ba73acfb61f4	humidity	{"value": 69.9}	2025-11-07 03:28:19.587021
bd4b28c6-d35c-4192-abd8-88cb7cd47627	8697991c-4de3-4a5c-9961-ba73acfb61f4	voltage	{"value": 3.3}	2025-11-07 03:28:19.587058
4f7c0679-1c62-4ed5-8859-07738673bef1	8697991c-4de3-4a5c-9961-ba73acfb61f4	battery	{"value": 85.8}	2025-11-07 03:28:19.587083
d52b0163-acff-4c66-9b50-dd57f12e8660	8697991c-4de3-4a5c-9961-ba73acfb61f4	wifi_status	{"value": "connected"}	2025-11-07 03:28:19.587103
eaa89e88-cbd7-4b86-bd61-1de55d9493ef	8697991c-4de3-4a5c-9961-ba73acfb61f4	mqtt_status	{"value": "connected"}	2025-11-07 03:28:19.587121
e7554f7c-5850-4ecd-9845-9dea27549d9f	8697991c-4de3-4a5c-9961-ba73acfb61f4	uptime	{"value": 866}	2025-11-07 03:28:19.587139
\.


--
-- Data for Name: device_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_templates (id, name, device_type, description, template_code, is_active, created_at, updated_at, created_by, version, required_libraries) FROM stdin;
96dc4271-9f2e-441d-baf1-5d0313488e1c	ESP8266-ILI9341	ESP8266	ESP8266设备固件模板，支持ILI9341屏幕显示、MQTT over TLS通信、传感器数据采集和心跳上报	Z0FBQUFBQnBDZWNOUGlFNTJTWE16STdta1BLbFV1R3hxZGdTbmJtMEtuMWp5RG9LNXRNZm0zcUNleU1tMTluRlhqZzRRcW9CODFaQWs3NTlFZFhNWXpwRUl4V2w5N0p2ZC1OdGJDZUd2WjNXT1BPNng1eW80WWU3OWNHcmFrZlhUdlFLQW9lTV85YnhMYnExRlJIeUZjOHJsNGxqcHpHeGxfeFhSLW1LSzNnekhEVmh3cXVLd1hFV296ekRTU2prVDhtLTlraDBZZWhEVXFqZUZUTEJXcGhaVzhRZ1FKSW5WbUhRR3RscnJKQmZDUlpoRmJqVE1JcldLZTJqU1k2cUQ0ODhkaDRGU3dOUDNTNVVrYjN2ajNkSDUxSlRQM2xETF9ER0pJZ1doYWRnN0NTOGU2V0J5TnRnYjZNOTNIT1M1cXI1WUhBZVdtZFRYMDZPRjVVU09pNmJQaHhPSXE4OVJsNzQ0MHBUNG80QU9HNGRraHA3Wkk4cDVIMTFlclBrT19pNWNxZ3hlS3lTVk1rTlNmRU5zVHZNVUpRRnozZVJjNnJ4RzRZNUdrczh6YkVkNU5XNWRMY1V4bXpsbXFpWVliSXBsRDgtT1VZOUhIdjBheHZlZDRJQ3B1S2FBTUIxb21wTFVhM3lYR2g3cWNPV2JXdllBb3lQcDU1QlZxOERubXFjU2JaOS1rWmZ4RXFnNGRUZzhWaWhwLWRXalA4T0JjYnFiMHFXeUhLbVVSanRRX1dJQXVzZjRvT1lMeXR5dkE2Tmc1TU5hQkNNLWFoMzNUX01kMU5iUW92MkVuMndXalVibUFDYmh1dnF0cmxjMUFSVnA1d083LWJxWVY4QnNaV294Q1plUjBQczlXV3FnYjNvRE82VEZNVzVoZ2J2R0NwVkNPUDJSRTY0V19RX1BKcDNxNG5NaDFPLWs4SDl2b1BfTTF5MFp3Q3dtVDdnZS1IRHFLWTNpTVBSRlZ3U0c0Mm0yQUNGV0pSTVBxczV5OTBRUlpfMjJaSW5odkNFVE9KU0dtTnlqRDU2MjJMRUJTZDN4bm5zTTExeUVwam1BNzMtWWs1U0tBbjVwVTNITTdBMU1PeWt1Q3Fub0pkX0QzNnB6ekRvckRBbWJ0SEhncmlua0k1NGx6SHJ0NjR5VWNSMUVIWElkdDR5YVlRREpjY2hiX0NtN1lVUkp5WDdaTTFWMFcwZktGQmNEVXNmeEFsTXR1a1c5cFlXcnNFY01kdHgzV1VHbE9fbEVBWEtuM2FrMGhyaFpQbk1tVnFCNHFFVHNEQjFJQUhlUmhlcE0wQVhYWnVjM3FYd0JjeFlHQ3hLRk1KeDNab2ljZTh6ZkVoNzZmRjBZcklhYWxIRktIQ2ZmYnAzbW81YjdQUVB1dGY4WkJYcTFjbzBqSkNpc2dZbjJZblNSa1FMdngyS0hHVEdNLVYtZURrdHZWdGlsNDN3TWVxcmkzSGdtandBM1pRZFl0STBCYmxiWTNLby15WG1YbG1TWWpSUWNFSG1sYmJydDVoRjdXVDBHZFhicThxQnF6aGh6Zm05RTFuWVNtelhMdmJJVkFaYTFiWEI5al9WcW14TV9yZklPRFBnb2lEd1RFTkU3Ry1wX3ZGU00xdXE1Zmx2VmZ2UkVOSlpBamVaZVZzUHVPV2FzNC15WTdEN0hXV3FlcVVjUU52dTA3eUloQVgtTkhJckktcUJKY1pFMTRzMEhCdWlWN1pBOU1CSURNVGlPM1NLbXFDWkNfMmNqMjJMR1YxM0xpazVNSGlHSEY4ZVJaOENVTThYN3VjX1JJOTVxUXZldXcxWGU3UHBzMDk3MXBvS0dsNDRSTGFFLVg0c1Z2SEszNm5VYWo3TGctWlhiSlEtVmVYdXRLRWh1NG13NEd1d3FRRGJ1TE8yblZFdmx2ckZSZGlOal9LcURMN0lfTjdYV29lV1pwVzRWVkNPZktlcC1YTkpsNXZhUG1MS0RXdkNSdlBlLUtRaGRIOWpQLWVOU3I4cHdIVW5KZHFTd3ZhMVZsN1E1ZXI3SWpyeTl1WUZHcjJCaURjNEI1YUNJOHpIZDE3SnYyVUQxWXpzbFVVaThTR1hkT1lrTzJ5dWRldFZXQ1Y4dWRrYU1hZHR3em54Wk5Eb2Q2Nm5nU0c3OU54WGplakUzcXdkR091ZUdXMXdoOUpqWjZmUWZYSFRvdEc5UGdSbFRmbFU2UFNjbm41enFrMVo1QUQ3WS1ScjdjYy1OTXBEaERTOV85eTJYbHNURm5CYmltc0NVZnRDcnRQQWUyNTdnVEx0V09ld010RlF2VmE4WmtBWFhsdVdWT0tvQ05kWlRQcVZYUjZnTEtCNkFBdmp2R2pfVEdoVkxBUHEtMkhucUlXYkZOTlJ0blpuR25qZ1Q5M2t0WTZITjlaSXhpc3otbFJfaWpoQ3J2eFNDVkMzM2NQRlBscmcxSGdyYUZJNWJBUFhOZHlDbnVfVXhXbXg4X2xaUDFxMTExLUpnLWNvMkEzUnlxN2NacXRRMHF6V2dfd2sxYzA4ZWE0ZDctVUNUWHVJMDdKV0RhaGN0Z1BjSC13R0VjRVItcVdfN2FwNWd1Z0JDSWU4SjVXX3pubFhxeURCdi1fcF9YYTN6TFAyeWE4Yll4VllKb2UzWEV2ZlhybHppU1QtUmtUS09KY09Ed1lMXzVWbnJwS0dJdHRPOE4tRjM0Y2VUWEpIeXJZb0xhOGlsT1VZaERveHdCQlhaQUVTU09VeEc2NkFaSENxdkE0Sl9MaDZNbTVGVWZkcGJDYXhwRElWZ01fdFBwNjktR0JmelhMbnpRcVJxQVFKY0l3azVFS3NYcDc4cWRCOWxITGF5ZzBDT1JSUFlxc3pYX042dGFBTEl4YWIzTkpHN3l5VXdTZi1Sdk83Z0NnSlFzZzZ0dE9veExsd1UtRkdPT1lnNUg2cnlxSWJKZzdKTzdNbElKM2VwbWY2cnJUSlF1aUxHWUhxNTFPeHYyWG1kOTRGT0hLdmdFSlBnclZwdFJOczVHLWJ5dlotQ3BwRldxVHdKLXc5bWdqczBULUYzSHo5d0NnV1JFZW1Qb0s4UUFKN09fNW9EVWs4eUxVaEFUT3h1M3h0U19zZU9SSzl5U08zZW4xTktxQVpPbUxIWVYxdXljOWkzblBKVmp1WnJkWXlmMEFoZFM5am5FYXBneElLeWhZVUNUN1l2dTNnYkZWNVBZXzloXzgzS05KNUUySnk3ek52UDhsMnFLQ09rRzlOMmpPVEVYVnJMb0JtdjY4ZS03NXp2UFg0UGVQOGFJckw1YVVXOWVxN2JGRUVadmphdTdGUkhrVFUzdjViMXUwUGJJaDhqVmNVbk1aT1BWY2lYZElhLXA1TF9YTHR5cHZPYlJqdFZ4OEtxRUV4YnFIUTJvY2tIM3RBV2E1VXRMNzNXUmZMWEkwTmZ5c1NfaTRBSG1IdkdjRDF5MldMUU12TFBvNk9td0VhcTl3WGNYcHVVQUJ5cDViUzBoUHBSX2tTT2lZUFpkZVZ6NkJTUUZfSGYzS290NlEzVjZoRnk4cHg3VzliTEdpaTlGRVphcjM1SGtCN1hBMGg2aThSNENyb2VsQWZLMmUtYW9saFJqTS13b2ZkN2hLWkJ3dUFiWDBlUUUwSG9wSUc5SjJPUmRpRjhGdFRqYUdZQndHdjVnTVpPc1FfWjVGUDVyNXIta25HNUNZbGJGRlJydl9od0d4OHpNM2RKbGdXTHRVcExVb2RzNWY3d2ZUelJhcElHQzBYMmRBX3VzU2pHbkJJN2VUYTd6TjJ3NFRxUGU2QlhjZWhWSHE3Z01vYS1vaWJPbzZjcS14QTgxVzZ5ZjBjRjR6ZDM0b2tlN1pkcHUwdUNUT2VKamkyYXFFTU9uczg0Qk91NC1wRW9tOUh6TVp1c1l0bmFRVzJKR3JPOTk3OEthNURULUp3R201a0Q0X2hfWHJXTE0zeGVnSlA0cEJpVlZ3LV9TdndVR25TOEsyZU5UUEZKeURLeXhGOFdJU2VtMG84QjdOOGFmd0R4Nl9CQUhSUUFZX1NhZWVjM2VMSzdsUWdHVXA0QTRaR05DSzgtU1JJWkJiNGowdy1sQlA0aHBNa2ZOd3ZFVUhfV3ItSXhNbF82OG1XaExmMUNGdHhYb1F2NHo3b21mU3FDODZQVHFLbEVEcVYyMFNiWDNKVlBINUpUWHJMcmY1aGlWbXVQMXRucXhnVDBlT1VlNHdiYUxlS2pXeXZLQmJNWTNrdWRMa2t0UHppbXZoQnoxTUZGdWxiZUtTbzMzSHBsYnJDTmhyWi1ndlNGS1pLd3NUWkY3SUMtU1kwNFhUaGd5N2xrX3pwZ25oRXljSUJyckpBVzBkRFJUb25zbV9OOUxna3FKM1U4dzRWQXFpcmhjbldqbDVNQ2RxVFNVMXFEaHZWZXJGandrZWR3ZjZFbVlqY1QxWVR4ZmlJeXFMSHpMVEhWak9aX0c5elJiVlFEVzJFb1ZIWGtCaFFscjlxb295OUh0anNhcUxPd29UQmFLQWY0cjhKNkxJWl9rN1NDTTdDT0dFZ0NGN1pMNy1KR2hxaEpzNFJNbUZWQUFNR1NMN1MyRXMzZVY2bzBqdXNIYXJCejdRSWVlZEtTQ2h0QWo3NTBvbHJFWTVscFpNS2NNV21hb2NTaTVPS1JyZFNCbl8xOE1MUFNzUDYxZ1prU0R1SExaNm1UWlY2VHFkTndhSjFRMERBUUVrTGJBdVZkYzJ0M3dyTm1kMG0tZ3Nrcm0wVHVKS3pBR0tTV2RiTEE1eHdyOFNUMTI3RzBCZzhzTTBfTTFnc3I3RjEtZVdQelBJcEoyN0prZ21sVF8tOVlRaXFrYWljNkV2dHdOR1piYjAxTE0yUmFzb1FWUGJsUE84a1ZLblozZXBFYzFiWjdYRjFsVjNuc0YtUUdZTVZ1a0xwSnNIU0FOTXJSZFk2X01XeXh0TXBMQTJfVGJWRVo2emlZa2t2ejhHSy11VHRLRzlQeVlacGNvUjBsdWxjNUZCMTItYzdlUWc5ajFDOWVIako3UUpyMXdDTHZ5b2daeFlhRHNwaDFad3pBZng5b0lKMHNPdjVnV2tmLUxvZndGMmNlTHJGS3FQUTNIdDNlMkJQQ0NuM1hQenctbjB0VzBXWk5RWi1xQ285SVp6RUk4d1g1R1VsaWg3Y2NudlBnb0MtSmxiR3RDQW5ZRi02UFljQWpxOGxmVVd3VTNLVTNhTklrT2JSampCdEY0cEtjWFZNbzEySGw0WmV6UUpMNDdmaXRRMnVtSXU3SHZGZmhSWGZjUkd1aVg4M3pjUU8tY1NiT1IzN2tmVm9XZ05fNHFXcEZZN0FoU3VMVVdOZ2dtSXlQMVNvVExRdlZoOGtuV1RGWlkwMHFKZDZVOWNQb09NclItWFhFZjFHV04yT0VvVFFmX3ZDNEhMMzJDOXZMQW00NWE4TmJNNFp1dndZSmluWHdHN1hxaWVpMGJwQkxJUHUzUXYyRGdGc1FlVXdPOFpueWRaWUV5WnBOdHVRRko0eEcwM05vZXFDcnAzSlB1RmduUVZfaGJoNzlrTkxwTmZLWW9NWVRrdmJ5el85NWd2N2Nka3ZiUnRQR2hpZDJYLUV5YnNhanR4T09HdTV0Y3ZoQ1hwSFdVa0FnOVlRQVJOR0JLTnZKRmFvaHE4djZuZmszcFV6UDFvaWZnckhqZTE2QlRrMHVOUnNEUTE5T2xXaEtLSkxvakc0dUJsMnh0VjVwVk80X1J6ZG9BcDdxd0phYWNlZE5aSlpKalJHdW83ZDRkeHM0eGM1U0pXUUFtYmhFa1FtZk90RzMwYTk5Ym5KRzNDbnZEQjFMcUhORXdodUloU3ZZUDQxaVNBdE4wUnl5R2JySlR2bGQ2cmlhai0zTnZWVDMteDRxeDJTUTViUDJITEJEay1QNmtBWUc0bHNsVm55ZU9RUlFqN0hUS2Y1UmtXYVN0T3gyRzFGdC14V0NFRW10UkJGQmluSFdwdTdETm12RHhsaDJPbGwzeGp2eHdpSHk1NEVtalo5X3Frc1JEenhwQWN3S0FZa19kYnVWemt2bEVGVjdkVFlkZW1ZUlRVektPSHNsQkQzb01tLUhxR0E4dWlJVnBxRG5WY0d5M3l6Q3MyWHlkRUF6ZV9fZGF1YUxfY2J3c1h1MUR4RDd3dlVXRk1yZjlyNU14VU5uNEVCbDRxbjh5bjBCSEVzall3MzhFQlpHU0YwR3AyR2RRWHVjNE1hd09nNFU4VTl5R0YxUGdhdVhlUTBqb005MHBlbEh2ZzRHMnhDWFcwem9oRXQzc2hLQ1c5TEZ6RGdabWw1SzctaEVSbWg0V0J4NndzM2JvNi1fQmlqMkJlaktxbC1xbjRrUTU3Rkpna0ZCUEt5bVd3Q2tFdDBQQmFDWmV2ekVxNGVWSzRoaXVVMXRjU2pxZFNkSmRRaThOS21aZHM5SWZEVVp6UkV5OUlSS0ROT3NlNDc3WmZRMVlDcG1CbFJaUk1uNk8tbzdKcWNFbnliN0kxOHFsS09GMEc1ZTZqVzk2Rjh1QlFkbkRlcy1jaFZiNFQ4RkRpQTZQSXlnQ2E0ZkhZNVdXZzhXV05hQi0zMEE5RHhlU1NpMEt1a0pJRTFNb0drM3FoVnFLTy1IT3NMV2NZUkZTR1dWMVhRSDdyZURSMncxZF9DRWdQWm1EVVpXTl9JTzZvNU0yVy1NemlOR01PbTUtbzhYYTFYTlRyc19Jbm1Mc3lHenhmcERxVjZtQ3R5QXY4LXBsbV9HYkxyZnJHcjJySEw4d00yY28zaXI1dW1jNnN3c2NQdXg3N0RqUnV4OXJNbWdUSWZ4ejR0aTYyT3ZabGttS0U0aGswX2ZpYnhlZ1pLYW9vMi1HeTFLOWN2NURRNnpJaG5LMzcwYm01bFpxeFE2NFIxeVB0dG5wM0U1QkxpdUw4S0pNelVJYnN2aTdvaGhoRlkzZVpRRXFIbHBMdzdNamxGYVZtTkJfMUsybE14U0xyQk5PNXdhUEV2X3NqcVkzdjN4ZWlZWkN5RkZoS2JsZXJIXzNZbXY4N2F2NzR0Q0xaNmZyMXU2WU5jZ1FidWtGX0x2dzhhWGEtYjh1dWMzUXZscFJNQ2JEZldpV1hJTkk5NmVMQ2hSckhzLVUwX3U4d21XVXlnU2htcGJFakhNMUFXOXZTY0ExZDVzWUYybTRQVzdOMXhQUWc0Y085c0M2N1NqclNjZnhObnFKZG5RUWpYRElJS2hxNEVLbFdwOFlaRFBDUVpUTnVOQlhSMU5RR3NWSDBlQVNvUjh6bkM5dkZidzJmbE1DSjdxX1lKczNEY2ktRjdwalpjNDNvNFpfYkJrbmlCby1ZbzFhSlFfdG9yUmxrZ19QNVpHOVdleEJDRHAxM2lxcXJFY1FvUGxlQWtWNFFtQ0QxR240dGZUR3RqM0UwdjB4dmNWT3htTFFRZ1UzUHlpMnNrTUZhS2dRcTAtTV83TENmYm1xWnkxTHF5X293blVHZlhtX0t3S3RzMi1XUWE0ZEg3MGl3U2ZxbUxTV2VGUlVJOWZLdExYT0JuZlpzbXl0anFyRVpLZGFCMVI5WXgwWU9ZUjVOc0ZKbENKaU5UZ3hJdHpRb2RZV1lpVGJ2VXpvT19jNG9xOXRMems2NmlyWFVWM1lwVWFLVVBBdTlKUVFnR2ZQVnBZbTI4d25HZEgxUjZ3MG85OUpQbHdMeFN1ZHhhemNuemtqaS1WSVExbzBVUG1hMTVrWjE1SkZESk9mR1lsa1lpSlE1OTZQTXVWUzloMTcyUTRaT1ZjeWhjVTZ0QjVTNzVUQjFVVXF0azhtWmFfaERvMHhqMHhDWEZhbElqaFNvTWt1a3J0Q2Zadmg0WXF5RmlfU0UzaUZuS0p1SzBRSTNVN0p4T3JiQ196cU5IY1h3U1IzUktoUk9uRGc0N3dGTzRvNExqeUFLVG9tSThLcHAwc3AyQXFfU0FncmdVNHNBSDdMU2hDMENsMW8xMG1rdkZGbVYwZmVYcmdtY0VmR2F6Q0Yzak1JQ1ZyM3RtbmV2c2VFVms1RGdsX1plRWFiMy1mdVZaLWRPaTRXUGZrd1NDaWp0WHBVNXVxLXJnUEdkbjB3b2ZDZnRReXd6MXQyUTRmQVkwTlhvMDI2dGdPU19KX3ZsdnMwcWlOcy16Y1NxV3dUZlVFN2dJZGc0ZGtQSUdINXNrcVMwSGVwcFlUR1VXb2xJdnNhcFJrb0JIUjVQVjM2LTFra21SZnpBNHBTaDZmS3E2MFlMZ2RiTlFBWWNXT3ByNlNYdk1XZWlVeTBfSU9mZVliTklob3FPYl9sd0djRm10Y1pSNXZ0ZGttNkhkMHRtMUVNUzZ4RktBejJmaWpKZ2Q1Rk1Na2J1eFpSMmlnbEUwMVdUUWVqaU9sWEF0ZmxZMEZvaHZHSU9UTDBkcWpQeGVUWnUzVHNZNmxUMW9mMEVVa2Y5MlBtZVl5dlRNaXgwdmlVUDN2aDFmeXRzNXZlRkpZYm83VGZQUnJqaWVORVJMc1N2VlA1UlBRdmxteUFSUGdnM2R4NWhsWWtpWDNHZWhTTFlEUHFqcG9lcWRsWUM0OXdLV2pPbWxoRjR2SVlBdzlnSWVxMXM4VmUyZkppYnB5enFMTzE1YVFVNVdsdEtNc0NGTV9tSjZZYmVkcEkxdFBLdHg2bDVBcnpLclVXNUtGTnI1aEhCRUZKLTFlb00xUjYzX1c3eEJXLTItVE1ZUVJLUjdGRTEySVlNbHdvWjhoVzJIM3N2dThOX0ZESUpMRng3V1REUjFjVDFyRVlULUUzbVlfVVhEQXd6Si1obEdkLVJpZHhkNkJkZWExUUJjSGJrLWJhQ3VUOHhjVU5yb292T3hNdEZ3VmdrbG5LN3YwbzVlSU5uVnE2TUNWTUFoakEzYmIzQTNmemxkeWRHdUhnQjUzVmd2aC1uaC1JelJyS3ItZGhHdUFqY1VHcFZwNVBtaUFZQW9HRDVjWlc3OXl2T2pGdndKUF96Z01MclRrX2drWG1XeldXcXJzcGlUcmhNR3EzRDFkQnp1VU9fOWJsclJjWm91d3ZlRWxwUk96dngxSE85RGdXd3hEOU9CbXBtU0x3dmhId2hiT2JwTGZ1SFBMbW9aVTZxQ0VrVFRLY0FDZGNDTWc1NHpqVHZKTC1qajNmREh4VFhRY2pmNmxxdkJMUHJrbDNnY1VmXzFIdkNtTVA3TzMyU3JkYTNBcXVNdWhGdlNRNEtJV1pZOEsxQzM4c0xfNUNZQ3RZOFE5WWtBcjRoNUg4ci1ZdXRmbHRIMTdhV3pfb0FLd2lYbHhLaUFPVV9OWlE0MHNjbnFZVzhmSGNCVlhwUktiRjVNd0k0eHJQbi00ZFFIcVRyQmI0bnVhV1Utek5GQVJMLWU5UWh0ZHE0c2ZxNzM3bXQ1RWk2SEEwR2JZenlZLWdBTEVCQkI1b2RnNi14SFg3RTlPdUZBVGVKcUtDZ2hpbXZ4VGQyQkNDaWtwREJ1eFpmcXR3VXBHaUdrTWRYbmx6LTlGcDc3cm91V3lVR0R6WU9lcHlsUHBvN1dnVnJzaEgtNjRXMTVnMUgtWFY0WlEySk43a202eUtCX0pvQnBya1YxcnFtR2d6MHgtNGgzZXlXcjhMdF9uRnQ3UzNlRDNkR1g2ZlpvZURPOEpwZ0lHVUtBem42azVNdWFWdlJYT3l3VnFrZW9aMjFJSkFCcFRvMUVLR08wbnBkR2NKTjEzSms0ZXNFNEVjNTVUdjNiM0pKZlVnVWJOWTBYaG9nU2x4Z3FhZWs2YVZkZTlpUEIydFJ2ZGlQd0VURkZoTU00bGlHZXlYazJrWExTZ09KSkIxMzZodnFfa0c5UUhKVWlBeTJPOXAwaG9tTW1DMUs4OFB2WXRfTFJJUkx2RmtvdjZhbHdDSEY5eFFjNUh6NEppQnc4RTRxaDJTT0JiM015bTRnX0lZTkkyb2tSRWUtUWZ0R0p0S1lta2s4X2FKc1JkbmxOOEZ1VG4yVEFpeTFHNDhXUm9Nb0ExOXJhcFI3OGdqTk8tZXg5WlE2MldER3JvaEd0ZE5WUnJHckh2NVh1aGlEaVkwMHdleVowS0xLX19lRkYwVUdQN3ZLbnRPYkZQOXhKaWk0eGxjbDAwTjhQQVUwaEc2NF96MXpUYnVCRzlOOXluZ0oyRkRYQ2pkaW8wSDk3RXN0M0hlaTdFYWlUTHp0dUtHWXpaVEpIbnV0N3Q5TFlLR0VKWlRiQ1dWSU93VFFuOTB0c0ctN0xWcnFSSVFKWDQ2RlV2UzhDTTBLMmV3UVRrSkJxcFR3Z3JIVUpFWmVGLXBlY0U0emFhZTJueU53MGxyMS1qVFdjSndhM0ZYU0hHdko1WHgyVm9oakNVWkt0czZ3MERoTEJaQWwxMHRzUmRsZ1Nxb3hQMmowWkFveFpBX29rclpFOGJxQVBRZjlodlJrUVRzanU0Z2JwQWF0Z2IxeEktQXI3cGY0UFZ0U3ZUejZad1hGZUVOZm5ab0ViUXNpVTk0RFdlYjR2WFkyekdIUkFUa0R6cjZwYVRrRUU5N3RpZXFBSzlZVmFjYmc2SkQtYzE3QUdybWNVODlaU0hrV1ZYaS10TklJdzJyZHJJQjVrVDl4UDRzVEFiRmdUQ3ZSZUV5ZEN0TDF1ZDl6a3I3NkRlWlFrTGRKcnlQdEJWU1BUY3BFU1ljdURRdlYwZUJrMVF6b2xaNFdONWV4eXdGMmRuUERWTmZtM2pxTEVlM0xDSEV3Z2NlX2M2ZzhNa1VkRW40WUlwXzcteDdHRDNtRUxzTU10Tm9fVkllM1RLR3QzLVVkTE52RHVRSDVJT2xWcC10RzFLZ0ZQVmltRGs4c0lqcG84djhreUxBUGVtU2Y4MWpMd0g0b2xQWGJfcWJZUDhOQjAwRVVYY0d3TGxkVjNoVUN3dHhqOVZhMVU2TDk2NmZ6OFZ3elVlcjU2RENMSjFLREV3cUJ2RmJSVXljelhva2dwYlRMREdlekNkVnZKOGp6TWstMDNydnNsWGpxV1d4Uk9BS19BNUthRFVqNzZFS0R3dVFBRUlEc1FkOXdWcmpmM1daQS1FZFBaMlRkbVpHQWtieGJlOFczSTNEQVJyMWJhMFBSSnBSR0MxY1Rxd0NIWjBZemx1a0VaeTZqN3VBTnBJcU1ESkdCVHVyNEdmeUJEYWJsSHJzSk1hOWNFbmdYa09HM0FSU0poOVp5cnYwRld5RmVVQzdVbDRvYmFPc3h1b0drTXUtU0lDZm13RURmeVNEZlJZbFNPZGxGZ3d5WEhwcEVZY1hydndoUUM4N25YSTEzRnZ1OXpVV29zV1NrU1FIRU81amQzY21yUWZhQmhTUU50elNhcnp6ZzZFRXRsZ2JQckhfYlJvMWEyc2Y2Q25zcWh6TXN3eV83Q2VXV0lPMU85ZlY2NFVyZnE4eGI3MDExcDF6WUx1RTdEc0d2V0RvZ1pyVndfLTBGbElSMTJrUjNYMFVPWDgwTWFVOHpOcmhxMXlaVW5jN3RBYzN4TDdKNjI0aGhHVDN1alpaNVZzRDNhUl9SRG9CTU9VX1Bhd1cyMlFja1VKSHVrM1ljTmpDYmpsTnVleGRLdXNPa1pfR0Fya3pjenlXNnEwVXRQWmdKNk00YlhJTFktWEY5ei0zcDhpaWdwY2dmbURlcVZINWpWRjRkU0pmWm95ZVZpdDBRUTZmUDBUNzNUdUdvd09nZ0ZHdTB2Tm9IaG03S2FOVE1UVVo1c2syQ2VNY3I2MERfaHNERlNaWUlUUUdoQW82XzFrSE0ySmFRbHE4Z2JuN2I1Z2JoLXcySGVBZVRBMnJnUHpMTllHRmVuMTVNSlRhQWRNcFo4S3JiQ1dsZWp3cjNlei1RTmJrTXQ3TUFFV3ZHdnVaRmpkcEMzVVllQ2RNUVMxWG5tZi1jZ216RzBLWFMwUEJHeEtYZUNSektGRHBPbVJmbkZ0bTAtSV96cFBidDUteVVtUkwtNmg3NFRQRVpETTh4bnpYeXQ5MDVraTY3SVh1VklRdUx5aEZvakZ6bzNLdTRWNncxdDExcnFsUGt4NG40NHU2VTNseVA4enVpUUZ1a3IwMnNpUjZJRVVRaDBmT2F4WHMwQXQtWTh6ampVdWMtRWFmRnRGX2RobnBSTXMzQ0F3d01WT1ItU1prb3F1UlloQUdpU3lOZmp2aV82OVowTzlsd1dwbnUtajFFQ1NBZjlMeHhUcDAzLWs3WnFic1hJUy0xSXh6WEQwV2t5Z3d1amZrT3hwSHdTSHZ4WFIzSGdJVHd0eDNlU1I5Q1dWWndHQzlEbS13TDRtVi1VYWFYRFRLVFFOZU1nOXZZcGF1eFo5MnRTSW5nNXJiOUtQSkRod3A0WkdwQ0E0SWV4c2VlRmZnOFZyaVV0bWVvb1UxWGJZNGoyRE5vWEt6Tl8zeDk1ekV0UTVxU0g4ejRmUzhndHM3aGVDWjU1blQ5WGEtQmd0UFViMFVhRjNmaU9TYUZvakxzQlJUY0Zxc1VDaHI4cDlJcjNlN0hPZkRBM1RwLTRNdXp0MndpY2ptRjJLVGhNNElwc3gxUk5ic3NNZ3lqbE9CSXBQMVFkZmhvNkxfSUtZZzhfVVBaNDYtcnhTRDlpbXR1NGlxUGdyS3o2eU44RmxYNnpmYkFhMkx2YVZWVUR0a1IwMHpaMHZLN1lSVUJmVzhwWnU0eXo2dU1uR2J4eDlSVTdjSjBZUUw5NFloeV9BYWhqYlNQeE5vN0h2NHhCbmlGblRCOVdMS1dnb29zdW5OYjk5UUJrNjR6YjA4ek53WWw2RFROYjR0ZUFYYVltbFU4dmFrMFBvWEhiMWpNVFhRQURXcFh5ZGZDM1NVZldBWjd2TTN0WUVjMmdrbEdsQUNoZUxnZkJ1d0pUTVJVX2xwYVlLMmRpWmotbVdVRTNLY2l1MV82Sy1JS3Jla2NncUJpUnp4ektZNWF0YklGWUlWanFqd3hjUjdSeVZXcjBKN2tRcHhKWlZSN1ZuYmNIcFpyelBLU2d0bmtsSUs4T0VFX2p0RkQ3LWJ6M3BRcEtQVkdLQjVmVk9IZkZTa0NyTWJvVWN6dVBicExiNGhWQi1xZzliNEdRNEtISXNWaEIzRkdWU21TOE1XRkk0ZmZOejIwdllmLThGaldneUw0aXluTlR6VUJVbUJkQlFlbVhEMExpU28tRnZrdXBkUUJkZkdEcEo5akN6QVpQNlN2QVo5UlFLWkxzdGFnVTBkMFhxNXdnVTlKelVLM1QxSmFOTXdnYnZ2eXR6bmxveFRqTVVMMGFycDBBYTRVNFdQZk9vaE5HaFRXbDFnd0M0NGFrdTRxS0p5V1FXTW9lc0xKS0VRYk5aMFpWXzctb2hHOGRRcmRjR3lSdlozRHJIYWlCRXVDSk4xUkxuc3BqY1NGTW5tRjRnUklXNEk4UFc4b2o4RG9idTVBdDVVV2l5X2pXUUlnb1poOHZCeE4zMktKd0ptTjBMRk9ZYlhMMURMc291eFRIS2JpdThLcjNta0p1RFhRUmJCYUNHVU1fSFY3bWF1Y3J4eDdBdmpyNndWamxITng0UmROUEl3c01MYXdMR1ZNRGtwVVVadTJiWm5RblVqcnd3UGg3VktpcTNleDJsbVZSWDQ5YWxtRmtVNHhETkxrWG91anRpTWNYVHZSZk5iNVZSeUhfbjhaaWFpOENoVjN1MFJrU2ZFU185WlUtT2k1Tjl0eU81TkRpa0JlMlJGMkVBZ2tYTzVmVWg2LXJlOG85Ukdmc0dpaXpHMzhqSDMyLXBENG1LV3BvVGd4LVlzYXZLT1FrUkdjT3d6cjhtTWlxYXQ3Q0xTTHR5a0E4ME5Ja1A5bHlMOVdwRE9qTGRFU1FBMW0xUkZYTlV0NkVFd2RVVU9mWkFqSUpnQzhmRjV0TkhzZi1VclhSaXFMVWRsRTQ0V3BZY0hxWEVCeTcyTXBncFdpR1JYWkVmT0RIUTV2cVlianZ3eWlkV0xrMUFBbDkyZzRiYU9uYlJiYTF0Nm1QMDNfcWhWUThrVGZ3bVF0ZV9sNFlEUWtVdjQ4aFVGSk82c3dnTnFjRUU3MmQ2YXdiX0ZFUXQ0NlBDWjVZWUtFY3pTa29KcTNPY193bU01TkIzWkwwVXFfR0oxTFEtWlpDWm0yakhwODNCei1DQ3Etb21EQ2FFcVc4ME1lUS1LN0RiSjh0aUhSbkJGcmZ6NTJWTnNIc1AwSjY1cFdta1dMdjVNWFh0aEQ3Q1ZzWTNSOEduQVJtZVA2QmRWdURCSUloMVlENG1xMlhYVWVLM3lqMXk0VGJYcUtUaWlIUmJ3ZUJuM05RSDdfVk83d1Q1VkEwS3V0amYyMkZNTXJLdV9WZncxWENWMXMwOGNrNGs1ODlaMWE3TktiU19Cb1l4d1c0a1lBeElEbGdnUGFzaXNUd1pBZ1BmYjJrQUJwamNBb1A2WE5LbEliXzR6WlB6U1FncDBENVRLSUpsM0xBeEsxdDZoaFpqU2JfU3JiNVhGQnh6alMtZFk3TTM3NWhlcENBSEdtNmRoR21XWkRZdGJONkJueGloeXdzNTVUUm9SeWxNYWlnRXFMalpXVzQxTDRSYmppTjkzYUxCTGI5TVEyck85Y2Jyd1FuYV8zTW1ubWNZdlYwVklqejl3bXNHNUp1VXlXU1BCWkJDcm40WDdUeVZ3RHo2UFFxTmhzN05FS0NLUG16dUlCVWtqXzFZVUN3YlZ2Y3BCNWNkbWxrTlV4OE9EMG1iTUthSWZMdGtld3A4V1JIdUh4dkFuZU9DOFp6RHBpXzkycEp4aFlQem5RMm5nOUc2OWhtVUZPa1YxVlVjT1dNd2dXMFdMVWZyR0QxZWpWUndzTlhkSTQ3WEwtd1IzejhtXzdkWG12M0JQakhybFk4NUxtZjNmMGU0UnVaQ2JnODFQRXRwSzEyOTlKYXlLMjJxNTRXVzJ6aTl6QVJ2WFJzZkFaWXhnVTRZQ0M3dWRmZEZ1X3Fwei1LZ201S1ZWLXZjZDVwdVdJMzNQcEVIN09vSjZWdkk1NEhwSFlobzNYNV9FaVFMNWRCbXlSWlFaTF9GSWZmcUJ3b3hzSEgwTVJ4SHh5MVdMaGxtTWVIMjI0RWJvVm44V3kyYm1kRGVhNGNnNDdmN1ZlWkdTXzR0YkU0b09IUTN1U3RQUlJuZlBWVF9HYVlnYkxWWUY2V1BLNldraDhIYVhfcEVyOC1pdHFHa0diTk80dUxtWDA4ZTJmdzJ3Wmo4QTNTd1RuT0Z1VkpnQ2h0TmNoYTQ1b0t5R1FNdTBFaGRNQzFpckRmWFJFeTZ1OXFSNVVHdHRJQzRQN09KOVJaMXNQS0ZzVFVqUzZKSWdGQnBndzRLTE40Yl9UMDVRQVJXMnI1SkppQkcxcG9zTlhtYnJIUXQ4eWJYeGZXckxRSTdqc3I1U3VsSElSYXRsQjN6Tjl5WkF1cnZPLS10cmo2SGIzVi1ldmxzSzg2M0ZQc2lHMmRoOXBZVzY4TWRKOTdRbzB5clh0OHM1OU9fSlJpa1VXYzhXU19pOGY0bXEzNFZzb1Q0OS1WeVRWdTVsaWhzeFdyUnpQX09lUGhoSWpyZVBjMUgwU2UxeFM3UWlZS2ljTHhuZmM4R21Vb182SDFkVi1KZ2NWZl9Cd2hxd2l0LWpYcFlNS0R1NjEwNllkZzdYM1Fkb1B4RG5HYUREckhGLVB0SEp2aENSV0pWZHdNaVBGcU5LZmRVa2pFcm1HN2hMUWs3UnhLY2I2NUYzR0hiSDdrU2lXUC02Tkpxa1dza1BEZFhNczVZRndkSkZ2Z0hvSFV3UnI0akZLaHVibGtlaVdtbnFHTThaZHd5ek5NR3B6d2hvS3ZBTXZhbnVOTEpCLVExSzE3OXVXMUJIRnBtQ242dTJtR19FTzBBbHpLQnBvOHpjTERYQmlVY05sWllZTXNrYi1JS2FfZ0pDTmh6VzZqYlJMWTBreWhoUEd3SjRXYjBBNnRGSW1qeWU2bHBBdjctVFdoRVdBUGNKemhVcC1TNTVLcWl1b3d5aG9FZndVM0k1V2ZLZjhuUVk5dW5ZRWdrTjBMclRaWDdaTG9GWXF4SGRjRUlRa0xoanBvNWIzS3B1cHh3WXdmUUNmWUtCUDNBS2VMdHhKYXBQUE1lU0lIVW43ckRfb2FNc0JDczFjS05vYlQyMllheXp1V0tfYjRobzhOazk0ajM1RW8wRF9jUVZoZlAtRkNaZHYwbFR5QWNJMmVUdzN5MjRyLTBvc0g2ZENJcWpMbVEwd0ZILW41dE42NGNkaFhvLS1PSnhvRnFwNUlxcFlFT0RtRlZHSWZQUkppbmVyZ2FncTNRb2FiWHlTRlR6bnd5MnozNExzWm4yUS1DQ3hYLUVCNVplMm9jWFlSaGxBalhpMjRLY3FyUks5SnhpS0pPUnRpUllMXzUyMUh2LWhVbGFPT0pMTzBzOVdLTHRzSWpwQV9NTGRxT0w0a2U3SFJzT2lYS1BwYkxBZERQR2NHRGtBdERYWTNQSVJhNEFRU1AzSzdCa0g4U1hOS21aNHpwUF9hUkZDNVlXeFFTNzRjOXVSR29xYW1EMWJqdkxaWVFuTHhJZlMtQ3ZlWl82c0RrYWh6UE5mQjNzaXo3bEJ1NjFMZTRIS1JrTFJlcnR2WjRDOTFpejNSOXlvZExMZGVDTjBaVDl6cUJZVVpodzZXM2dWcmV6bFp1cWlMRlhxa1Foam9UVjJzTjNNS25YRGN5OExFc2VVRS1OaDBLMzViSjctWS1EcDUzN21Sak9XQWtWTDVQN2lSWjFWRHlmZHVtZE5FcUtld2d4ZUZjazJTN28xWElYXzJzSU0zODB4X2ZiNldSTXdDYVE0OU83RWJteDlVLTB3NHNieTNmQjlBZ2wtbkFEUDM5endTclJhUGFZaHRvWmNabHF5dmh3bHFkeEdJOUVsN3p4b19XN2U3V3o5WUpzVHY5NG52N3ZHVlZDY1RmaU1keUF1bzRLc0lxWUFGck9GdTdmcTQzTE9jUm9Fbmw3d19reC1GZ2FiR2VQSHhVUTlfRGtvY0ZDdVJVdjlwc1Jqdl9DOUpxVUU0b1FJZWY5SnRrWlhRdmhsMW5HaXc2aVpiQm5Xdmp6akNoemVKRzVsMGNPUWhZdzUyWG9MaEo5QVhZaHlVaU9Ob1RQdEhsdHhtd3Zabmt5R1p1anUteGc1SG10eFlON2VNV2FSZ25mUXVKcE9FRzFtZzV6bTZ0emgtRTEzUEhqVnA5a3R2cGFpWnF1WHktcVlhME9XSV9sSTVuNlFHclR5MENSallmSDFQcHQ1VDN2SlVnM0ZPU2JCX1J3SEF2M0JCb1JwbGEwd2otdHc2SVFKWlp0OUJVb0F1d2k0QmFwT18tZVgtTS1wcW5hb3psRnViQWVZaEtuRDhTQ19wRnVyenhiZkxpQ01zU2hGRURyYWExbTU0Zm43SUd4bVZfT0lpMUUybExidE53ellZb2FERlJETzBuS1VYR0xubDVvRl81N1paU01rMlFYWWJjQ0E3Um5nMm9qMUFhR0pfUGVIQWhsdWZxN3F3MjE3dkhSUm1ybFJiYVVjREZaRmxUUXhKZEJJMjhkcDlLVTVEV19XZkRKdjF4WEhTa3JnR0xOaUFMbHJQbFJOdlhjOWxOcjBOMEM5Um43OWlkUmxjd0RCYTJPaFdpOUNrb1hEYURhMEhSeXdscFppWHBWMlpuUjFHa3BlSVljSXJNQ2lqb0F0dlU0S2p0NDhFM3k4ck1KMldPTjAxWXU0WDZaTzluUHhndTNZSjhfWEpBdjlCYVlPM0NZckR5Qnl4MGJaY1BUMnZ5VzRiNHo3QkxxZ0g5RlVzYjRZMV9SeFp1UU40RnllVkk5MDlqd19Vd19nQ25lZkExa1hvaG91Y1JiaS1hSzRKbURGZ3ppdjZPdndnV3VZTW9OUVFzeWd2ZGZSUkI5M09pQlloUlIzd04ybDdwNUNFbWRuZlRDaTBuQnRRemJLcmhUaTlVenpTZVZwMFZ4a3RNeVBZYUZDem1JWVY2dFoxYjN0UXQ5VmU0Z2tnd3U5YkJFbWRPTHFEa0s4XzRwNDdoQUJ1UDRlVk5TRTFRSDlPdktpbko1Z0JLeS1OQ3JZRGtzTU1NcnZCTktiWWNHb3k4MEY0TkkzdmZ5MG9KeVdFcDNJMEZrdHlBWXlwOEJGTjdMMzAwamxIQTdra0lPRFk1Yjd4WXlwUmhYdFRsZG1rNG1TQ1lyVjZkM1dDWXhNU3FuNndKeWUtbzQxQmduNTFNal8wSUpmNnpFVlY5S2xZNkNoay13eDhOZmJPNWcwQzRLdFhOaThZMXU1QUItWVhFblN6S0d3MUxaLVVoeEh0bkExSmRKVERaNkVyYlQ0NlFHcHBPVXp5R010UHlZT042Y1hZNjJSMUxlaVhvam9GS3RRQUFEZlQ2bkVFc1RiYlRFelpYSk9zREtBLVYwYjdfWk5MVGFUTXNWbVVmWU9fZHY4RjRuV1pFYW1HRl83S0tpQmV2TjZheUpveGwtLUJGczh5SjNjTWFackIycWQxamlOS25oNV9tZ3JPNFBYa05tS1FGakFRWFlhdjI0UUlYYnZSaFRjWjZDRDNZakVrTnZrak5naVBES3VDb2Z4eTFJeVdWVUhRbUdjSDRYc25uaHZzT2QxeEFrT2E0bDBJRUZXVHRzdGhvcTduVm1HMVFzcDdsOTdfOS1jTkFDdzRDVUVnczdxQVp6YTFjRC1DNTN4Z1U4WEdvZVhTeWkyLV9uQmNZb0pXVTNJaFBZSmZaMnhCdnBJR3RlaVBabG1TeVNWM2FMTUMybHpfQzR0Rlg0NXlmQ2F2QWpHYWVrT1pfbEhVRlg4b1N4U3JXdklWODZZSV81X0E1SHVBTmpadjlxWHpPYmxBajB2RkdwR3JNWWVfVmEwc0N4ZE10X0ttWkpicDFnakFjenFkd0hkLXRudEkydmdQdm9leUVnUS1DNVFsbFpMWmFDMnMyUkpsRFM3SkZJX0pLSzNuUEVxelZxN0k0b1JSXzdhOXNKZUhHb3JoOElZMjVoRlFQU2lqNHBheFZCLUdtWVZUVFFIUkdvNWdRVTU1Ri1DZkFtLXBCZXFwUU9lZFZ1akJlYXlVOVRZMHRRZE9VM1Q3WG5fOHlwUUJpc0dGclhiN0JHTzNHOThXTzVUN2ZuaTFsVXI3Q2UwUUc1N2dPNm1rUEhSNjcwX0RIVGZDSVBBeHZxREZ0czdlLXJ1UHo1LWx0WGhoeXNlZFJXcGZWZ09YWE04YVQ2RjZaYUYtR01YUXBwaEpkUUVHY3llSjAwb3h0QkZZbGdjN0s2QkowbjhoYzNEY21ldmNSOTREdUlpV0U1NG5DVmcyZzY4b2JaZ2RFekJhbWcxOE5DbTNsRFlYdldMZV81Qk1VLUJvNEdMSlhBUW5WRFJVaXZMVWVvY09VTUlraDE5ZXJRWE83LU5lbm5Xc0dQakFFUDJxM1Vpb0ZfdUgwTmhDYXFiZ1dZN1k0M2d4bW5jMVBJTE1DM2pqUzdOaW1qcndjZnRuT0loZ1QxX0pVLVhlaE13Rk5YdW1fbUdjNWpndXMxblZWTjJBTFRUMHA2WWZRdllaSnY5NDFrVVpsLUN3MkRMQmtrZTRxWTc5XzNraHd4aFBLVlJ5UVBtV3ZBNGxXTUVXb1h3VE9CeGxvTzlqQmJoTHVmZmx0QzNmQjMyUmlvZG96ZUhJYnpYblBHVzFGaVFHMFAxRkdGRnBtUW1JUm1uemstTFJDMHRkUjkySDUwejk0VFZPcG5WTE5RZ0hwbVdHdFl6SWN0X3NqR0hiQ0hOVm9SUDZwNEZPVXVZY19CSE1TZzZ2LUVoekNuUWFXNjljcTJvaDFmMGVSSS1IeURrbENyS2taTDdrSlAyd0RZTGN3czFLS1NHdUs1N0RHaTc1UmpZMEtpRXFUVWlMUUp3YTlYb0lBaWFoOEt4Tzc3Xy1vSDhQUVhXb2Q3emEyV3FhTHVReXFRYzdOazNLYWNENGt1VUNCMUYwb0pjZDczY1BNYzU3WnM1TWpBN3JYRzZSS1RXZ0V1QUZKQU9zOGM3NTVDM0tSdWYyUm1md1RiaGJLMF81M3JtNnJma3JubDVYbDVEcV9SQm92bUh6RVBmaW5sbW53c1RsUHRQSDdvVThjRXBwTHM2RHJhcmR2cmRBWkR0UlpaLVRralg4Ty1WQk9BQVJCaEkzNnltNXVJSWVmQ0IxQm44Y3B6QlF2MlM0UV9CNFJvNnBCMlM1VWtEeWs3b2s1RVFoOEs0TEg1ZXJJVHEtMzQtQ2daUTRYaXBsWjJ0MGNMTkxsVVluOGtITkJBQmkzZlRwVFdkdm4xNEVnNDduLVUtQzRTcVlqaUVsSEVQVmNQRFdxYXE1WjdZVElfSVhJSmNOeV91Z1RNV09Ib0k3RTVRV2RvYk4xeHd4SC1oWDc2SkdsTnpZdjFMWXp4QnZpUFdrRXdXdkoyR2VKWmFGQV8wVXNQUnEybmpLSTBmQjlXaGlVZVpTRldHZy1WLV9mVGo3Wk5DWGpDMHBfT3Ztd1FVdnVhd2pMUVpjSEhvMWdNbVBRYXlOYWZmZjlMMTlpTUh0TTdQbzB1enNLeloyNDliR05qLWRRYl8yM3ExZnh1WElzOWN5U1pTTWJRQ1poWWs2NlEyYW1ZLWhkYkRxMkxTVVhCWWJLVjgwYjJjYlVncG1mUUxNbU5vWGh5eURJUkgwa2tJaGFEU3FJQW95Z2JxVVdtblF5TUJ5WXhDLVlKT29FZHVCMThCbTF6eUNFeUlrMUtrT3lmNkN3eFJzZEpPakR0Q0daMUFKOXJPSmdCUXlpazVBbzg1Z1NNWWlMV2tGV3VQU21HUUFKVmVoTUYtY2VBXzV5aVNsMGd2WTExWE9VeGdlc0dFc0k4UndyWHRwT0YzN0xpSGFZaUN0c3ZIdlV6Vmg5eE9oSHFfbHNQR042TzBjVjZ4RTBpRmQ5ZFJRbmk5VTdZZXd3YVcyXzR5QkFyUk9lYUI4S25lRjVKN0NnTzNzdmE5SDF2YVdtTjJJV045dF9hUFNGZ0RNV2pBdzNrOGZ4MFBEYWoyZU9zZ2ZKem03WkZwbDhFTmhkZkRkN0NndEZnN2w0R3RjY0h2NUw2dHgyUlJmUHFzbXdGWDV6RDYtZmZzUWN1dUoxWjZuZUlMV2IySm1FOUpuOWNmb09wUkNWTDQxRVJTVl8xSEx5dHEtTGNlazhGbHk5NWpDSG9jODRaUFlMY1Q5TEdqcXNJRk0wdHBfcVdWUXNuMHk1MHJFMWlKN3R1eGZ1eGUwQTlyRHZvbVhXcmRCS01QUkJKRUFrVTgtdlg4YXVVV05QbUxrdzJmY3dIMWdBQW9sSnZRYkdiYTJ4cTluWmNkd09TMFZyZk4zZWdwY1FreG1jUUk4MXUtNDFvaDEwNE1aOU03dVUyV1FsN0FSNWNTYkJzNHV0VmtNWkdJNXl1T25SS254UFVMa2JIRG9ySnVIQnZkZlRrd3ZpNmFjenF3VkRCTHBaVVV5RTRTc3VMcjE3RUNwOUw0Mll0dmd3MUo0bjU0eUdTTlhpQ2hCREQ1UG1vS1hpWWVEZ0tKSmJhajFOZlJpMDZFUEIzU3VMOTBUT3VobG1jSkpTNDc4VGlFckItRnE1MkRiRENQZElaN28zdTRqUVRvOFZyQTh1NnlxdVEwcGpJVjRqQWhYS1J4S3lzMUFqSmJMN09IbFVQYlhWMVMxQjdTVTJhdWpQcXNfbnZ6NlR2LWxVV2NRWldnN05qZnVhT2Y3eV83RmhhUXBCQ3RNUm5WN0xoa3c0ZmlDMWZMNV9wczk5bGllUG1XUDEtWkh5aW1MRnRpZXRqYUM0ZjB2cndUaXlGenJNdlNRX3U4Q05FSTFoWExWMjJaNzdtcUoyZ2p1MFRCOHhIZVZhQzZCMmhRMjdwaDNkNFpqNTJlNXpRN1ZCVmk2WjVUWEFUZnlNclUxenNZa002Zjd2MEQ4RVBsRmM1QTM0UEJMdlVDVEZfRlJYRFk1eFRSMHZnbTRtRmNTLTFjT2VucmdOd3NaNFpRZ0VDZGFwdjU4VzhoU0Fia0lVWFl3bUdWaTlTUHJacUQ4MmUtMDBZenZJU1pjbEh1aXNudXFvQ1JrQWZ2RGZwT0k4ZTM0QzBZUFk5cHVZZzlJVGE5aGt4TGdhX0pibzlmUkZNNDZtRUhEVkZ5ci1wSkFMd2I0TmZvbXZjT2VjdE9lQU1HX2F0ZFMzVzd0SE9HakE1dlVxV3F4bUs1WmtCVkQ4bkRNd0pCOVphWDFvQ0JCVmFnQ1ZoUXRSeV93Y09vS0l5YVlaMHZfQUk0bmsyUGhOanl2LUJ6RHpLX3JyU2xONGd5dlltV0llTld5Y3FuYTBibEszQy11UFAzd1N5Wm9OUlZoRF9fLWlMSGlpdDB3VHVxYW9WRURzSVhyWnFzRGtBODFOa3dmSGFVc0FVZUhkMzF2OEQwaC02ejJfNTNLeHBORExrbm9hWXB1UGk5NmdzTzBsTTUzMmpfRTZRc09yYjBScTJNYlQ0YnppY2picklNcFA5dllyUVJaa25BSzhpdmpvMFZEVjlPeXJPbW1EQkpINEpVRVNnZDdtY3FGdVgwdkphUzJYaGxQZnAxLWJlODFIT1dicHVTNENfeVVCMmtibjhyTG9teDFrbGRtTGpIUEZsSGc5d0hjazBFbzhBXzRTblpuT0lSQTJ0NUpscWUyUERpdXZjZVdRc0VVdVVnZWNSSXdhSG83VVdpTmhKcTNxeHJpa2RRMHNlSGY1TmxxdnNlY3d1eGozYVBxZ3JoQmhlVzQyNEZtN2FvZzMwWXhXSmV6Q2JndENYUUd1NmNMSkNzYmlDZ2lmSFNVVW5UUlljYVl5UXExem1aQXpISlhJU2hUV29LdlFPN20ybWozYzlpenhPS3pGNEphMXppb0lDLWlYb1lXMDFUbkllUGZZWW41VW52TThscTNtVVhaREV3LWJKdEM0bFNzY0FnRUdVckUxYmEtV24yV2RxZFJMSmUyVUJfblJDTXJ2MUtwdHNvcEFqYzNlVDA1MUh3X21ydDdiV0dEaU1BRDlManVSdE1IOF85QXhxYlk2RXN1Nlg0d3ZUZkNzRkVTaWRKQ0VnS1lVajdUaWk4RlFlQ0Zua25Nb0NtMm9BS0Y0VG5kVFhOU2RFTUNKUVViclB5RGlyTlpIbHoxckxoQW85UlVhZldCMktkY2xjaWcyUUFVdFp3dUFBX3EzUmc4RjhLS2Z1RGNtQzdaX0xRN3YwSTc4UGhJMkZib1ZDd3ZJSEttX2FzRV92bDlzaWswVmQwZWdjOFdWWVkybE1iV2FyTVpkNk5Za0RackQxUWVyNUhGa05KR3lzZERrU0ZzcHB5djlMc1lqZU1sQmlZdDJ5RjRjN05YZ3pUUWczZVRiRUV0MjhuQUVJZHhxaDZOSVdUZ0phbjduSEc2LVFFWlVyX193NFhOV2d6VWxsSmJOQk00Uzk4SnY2OVVDM2w4cmJDamJZT1d0eDFKR193NjR1QUNQTUZUTHduZzYtQWtqb0FKaVhJMHdOLVNLVzdQXzBZNVZiQjJwSWt6YlByUmJwR18yaElLQUFRTjN6NWRDZ0UtNlVMTnpCTkcyQWRQT2Y2cjVnMmhhVlVOUzJ4Sm1BdXZKNm5zZG5IVmw1MmJ5TE5uaGF2U1gxSlJaajBiNmVLbEc4cUxOUnFzZ0NqQkgyTGZIX19MTFZfNTJMbFJxTzFsb1c0Y0NkTEM0VFl6MUdTUFRydk5QM0ZiSHZuLTkwSjBmZnJEQWFtNm9nYzhyZHJmV244cENTZEhlT2RZYjVPWnpmenc4TDA5czVQdUNlVmVkSXpJc1c0X2pvOUdJM1dBaThoTHpHNzF1OUVfREx2V3hWZ0xmV0xGWmQzN2cwdjdKcFI0eEJVbHc4T3ZoOXJjMkNoSW5wZXVXb3RqbXgzVHlyLTBCM2J3aDJfOUUyOEdLcUY5YzdFZ1BDZHptY0xqSGxSbzhmTHZCa3gweGxuMVpDcWhwbGVuT1Q2ZWVwUXZFeDZPcy0zTUJvdFRlbm9KcXFvVDc4X2lqYzRFRnByME96Y3FSenNVS2xmQjRHbV80MDEyN3BYTVg3LXhDSHlzOGZHS1Nfd2VPRWJrbHJwakpjTzNVaWllSW9SdDBpMkJNNTRvcjdmd3BjUjY1ZUdCeHZpWjBxNjBFaVdsR2lPVDlUOWc1bzFBR1h6dW1WTnVDclp0ZEpReEh2blI5Wm9PZDkxQmsyemZiS19LRVp4NGhZSkNjMTV1SkQ4SVZVZE55RHdyOTBnMEc5eVdJdWtZWTlISVRDRHdkNzROS25jN0dFNEVNbkw3ellqUDUwaGFnb3NsQnBiZFNzR1J0YV9oaHYtV3Q0YlB0S0VXYi1mRmo3QTRhdTZsYkt2dWFCTEoxTk5TLUEwQkpSVzRWYUJPbVNkNFBSZWE0ODVJU0t5cmptRDZGLTFJX3NZbzZ6bGN4SllqNk9UUHVvZ0VSVWFaZW54YlNlX1I2SkJLaVhpTUoyTzJjeHBYeTctNjFnME5BeFFldHotV1hvR3RfTjdGald2RHJ2WjZJbE5QTlVUdG5BdXgyb1RUYWtXUEdBOEc1MU0yaFZ1NzA5RUN0a1lRbm44T2ZGd2dWQlVMUHJBSUxWMXNJX1U5OXBNSmFQTnBicnJscllvTjJMS2kzbVVETm8zd0w4N0xrRVYzSnlTanY4R3hiLUlGaWJ4M2ZXdXJzNV9mT3Q4MDhvVm9pb0Uzdjh0czFJeTRucnN5eEs0eXBmVlRjaWMxbGYwa2N3Vk5fb0ZZcTd6V3otdXJWOGNneEVldk15Q3FlRTluVDh6WVFLXzVrYzJpMHhDa3k2Um9Zd0JPWjVMd3pMaENySXpyVFhGZW9QaXlNazdPa01tMV9INjIzNm82Y1Y3dDhXeDVvT3BwVFdUMWhTNWliU2UtaUs3ZEEyTXZUb1l5c2ZqS1haSHZ5WVFZcXp3b0U3RURUdjNpMFB6NXFCOVowcTdrMUNaTTZ3QVlKVlYwVWtOUTZYX3FXVEtESkVtT0d5aDNXMEsyX2htbnJUME1nZUo1RGJWOVpaaU5JR0JVODBnMDVhQzRPcEtESEZkQkRyUHg2YllaazFPemRTeDBFMm8wZzY1MWx4NVY5eC1KMFJKeDFnM3BRRHdoNVJlXzFYTWdFMmYzeFRjWVdMSmlfcy1mVlBKQ3JWNUZvQVNYWV9DeUFjc294RDAzeGxlRVJ6Ujd0OGNBYUJVSlpLSkhCSkhJVlhsUTNWRU9aejV2QklweE1YSHByS1lmUlYyUWpuU1JvU0EwWVdidmc3d25RRUh5aEJxbF9NakttRWpLZVluZ0RMTUo4X0xpSU1oQWdCYldYc05TWDlibHlfbEN6T1B6R2oxWFU0dzcya2poVzdYVWpRSHg4LW1TY1BvWnZKcDRMNWRqeXZmalpIa01RZkE0dV9EYWVQbkppaXAzQ284U0tZZGVqRkhvUXJ5Y3hUSGpCODF5LV9uREV4cVNIbzFJQVY4ZS0zWTFRR1NLWk5jb3ktTFFMRFk2MS1QNGlWYWkzdmVVZ2MtVC0tQUtOalZBMTlRRjRTOEZPWGFCRVh3SVc5OFpqekQ5THhxdW9ucmhHV3FyaEtwS1NsSHkzUVEybzFwMWJDVjlKN1NOWFZRY2VrTDdFMm5Fd1pVcjA0aERxQlJIVTFGcHhMc2otTjhhcE1MR0ZMU3JXNktWcjFueUl5N1VKWUhWajFOOG15VnE4OU1pZVI0MTJaMU5fbTFvazVuV3kxS0hkbThrZElWTlc0SC1vUFU4SURlR0NvWHktejBLZ1NYZm95Tl9FckRCTmJrNDdZX2xJU3V0RDhoLXlvbkRmdVljQnREa2Rtb1FzNDVDYnlsM1ZSNk5CV0VqMVUxUnlNb05Cc1ZMYXM1ZEJ3R05fWEtzMGgzRF9MazlBc2JiYkJ4UnI5YW9PT0t0NlhOTUxlOHhaWEhrSllJd3NWUUN0c2QyQ3J0T1BfbGJVeXp1QlFBYm5PYk1XUVNmaVBPWUFNcnR1Y2h0aG9zSWpOTHBjSG1JSC1teWpaUkNZeUVMUE5rQWZvV00xVVFKd0hncVoxemlQbmt4Y3l3UTVPZkV4YzlqSXc2bE95Q2k4anl1cTY5R1BSa3FmZ0lMa09yVmhtRTB5ZVVEbVJGRHN4V3lyUkd5c2NqTXBkYV9QRF91NXZVVEk4a0VGcTM1a25ZeURkaVlXRDI2NkNwZVlRaE9Ba3FHc3VLOW5oR2xuYW9Jb3BYVG9oNGV6bU5qZEptTXRiT2h6MnRZT1Fjam9FdE5VT1JENkd4UWZCOTBVNjFSSEh0bXoyS3U5Qk9KeFUxNUFubFVsYk45V1BfWDcwajF6MXB1cG5kMUQ1X0F0VTNKRUxKT29fbjREajMzb0taQUlPNERoaXRxOU5QX2hRZ2lHaUlkNU11ZjYtSzBmSG1YbDN1T29HQ1F4NjZwMmJ1TDRQdGNHeVJiLWtOUnQzVTNPTk9CanphT1Zuc2lFZ0UtU3FMZTBLX3ZNWmRzdWhKSUd2Z1hHbG83enJuTkVXMF8yS096S3I2MzB4SVdlMVVVNGZtaEE1NkFwWmM1Zk13VmZIa1NndFc1MkFIanpJY2tSMTE2VEVpaE5qV2pHaDhhWUllTFM4YmpmdVBKeWV3SGVNUGl5MkZQOUtOWjJLMHNkYkhiRFhTZUUybXE3TEJFRGZacUV2aHdKS3Y4QjU4cWZ4Y29EZkkwRUtoMmQtV3RMMFItYjdxSS1HYUVxNWpGUWQ2Q255YjNyMWcwQlhLTVF4M0ZSWUlkXzJram9DT0xOR0l2QzROYkd5WlRadHRyeFBwdjQ1S3BWRnJqZFlKSzBLRnRrYkxFcEVUSzZRWHYxYndxeHBnVEpwYk5ueTdCRVlvU3R6emV4ZjBnbWEzZTRKNUtvVVJXYWJDMnVUYVZSSnd2U3hhQklZOE02N3hycXRHUU5GekIxZWVRNm5Tc3F5ejBiZjVObUY2VnVGQ1Y5ZHl6VVRpc0JDZHh6N0hLRFhKZHpabHQtaW1ISXNkN2JuMzJ6QUpEMEFoV2EycGhkUnhSSEIzMlI5blc4amhVUC1TR195RHhHaXRiQkR2YzZ6dEw0eDB1ZVhOSnZjWmpzQWVQWWR2QjU4SmphWHlUUU44aG00YURValFYR0w1ZGdjUTJ2THhzQVZTZk1mc3VTUUlvLThzZEFVcG9qM19tREFnazdaOHJ6X2tGd1l3a05zTWFyeTNyRktJajd6MGdkTzZwakR3ZzdLYzVJVTZMY2hNSlhpRGs0S2NqdDdNMVJnUWtyOXRmaDByaXp6OXc2ZnFSdVpVdXdzM3AyR0hkZl9jZFpZZllIanBfcnBLMGctRGM0bnZnQXBaTm1FaGZVcmU0MUtubmx6NkNfZ0tFZGFlekZVT0FBVTdLU3hhZEdoY05LcElYTENBNFRHREdTcWVZMTRzR3pYalFXNnpaOW4xNG94MlhQTldaSnBnTVV2TEhDektQbG1Rc2Q2LWZzZ2NXdVJJNDJOZDlHbGF2QW1tQWdpdkNqM1NPSmp0RVlDMjlmb0RVbkdqdVRXN2dOYWkxM1V4Ym1WZ2RFNTc1QTZMXzQ2cnpUUmlRcVdDZWpmQm9jS0xfd21adHZ3a2RiMW10VkZYTlZSTFZjazJDU096RzZISnB5TEk0MTQ1bXI1NFVxRXFzOWM0TUMtUEY4OTFLa0Y0SEEwS1V1MXBrV2FaYXpzVGttZTdwM3JpOHFQYVJmaWdfdExLRExfR3ptcUpBWGoyR0JIVGV1UDJjUElUVXpiZkU4ampFSWdMb3VVMUd4X1p3ZDR2cWwzM3d0SnQ4ZnRTbTEwV1NyemdzVFNnaG1Vc0kxd1pXeUJhSlpYUXNEcDNVZ0Vkb0cxM1JoNFZ0VG80dkp1TE9UbzVCSDRDbHRkTmlpeThWYUFSdG5oSTg4TnBGTXd3X0NwdE1FSHA2bTZHZDhreDJGWWVMUUtnalRiaXlCX3NsWUxnSG5UZ2lwX3Brb2JlMFBZRlZ0OVN6dlRGMVlNVkh1dFNvWUJLaUFXVnVaLXUzdVpGUWhXYS1FR25vc19KQklSbkZFSDZFMHVOdEx5U3lydkZlWnU1N3I1RTQxNjZsbTB5TWV1NFltaWdSYjNxNkhRWUYzVEp1ME1hMUdZaVlJMi1ONDBxbTNXWVZHX0c4VVEtVGY3NTBRYVN4eDBaOHJ5N3JpdkNYWklYZmF1cWVmX0ZuQVR6SEdYMWF0RURXZmtIaTBVc28wcjlnNXNyRmlpZUZuUTRXVVU3RnBtdnhjbGZDd1RJSXdIWER5Wm5JWFZPa1BHc1FMbkh2UTYtbWxCVGw5NnVPTzVtZG1CLWhXbmhMcmFzNW96QmhVOG9GOTRlODNpWHZuR1VwdTg1NVN2azR1SjVIbFU5RjU4MEg5VllDWS16SDNYdlFXNEVodFl1UVVoYlh2TmhHSlU3dGxHa01FX1Q1cjBtU0R0Zmh2N3hMWDhvbGdNY0dXM3M1ckcwcWlMdDl4M1RGbGhQRVFCMjgwR0Z1ZXJsQjduLTdCc01uUUFVTDRwLWM0UFJRZWFqcHNNNHFQWV9QRFEyTG9seU5hakdyZWhJUzdoSGZpdUxYNFNnbUtQdWFrMjJZX0pDMHpyRTVKMVRoM05MeEx1Z0xad1k2ODZTNmhuQUNmTVh1cmRJYmUzYl9sc0dHX3JjN2lsNEp0WUpKRUkzQW9IMk5OemJseWpOVGRmZWhBNXA4QlV5a2xxUWRncnFaSlJKMGVGNURVMm9VaURweWJodlYwcGt1cm45aGNWTDlJZ2ZWOFppWVk1MjJpd2lJeFZSOW4zOFRRY2g4M1BfWXdXNDdkRVc2V2IxTjVoRDhwU2QtVzV0QjhOeDhKSGR5SlRWYTF4WlVNM0t1STZJYkxKZmZNRHNKRUQtV3BCRk84X3N1US1SdU14MlJtWW0xdkQ2TVVTTDBuTm52R0NOc1FaeFlZUHQybi1OQkQyaXpzTkRnSmxZbDVPNEwzbDhvX3hjNVdFbFdmZVg3SVBnSWNFLTN5cDhEWE5FSlE1cnE3akRTQVJyTngwNWY3RVNzWklSSmduRlVzM04zdU1xcnM5Ti1jbXBBUDRsbWNhVk5RcUk4YWNKVjFkNEc1WThOdjFFS2tZa1ZOSzZyZk1mcTBoNi10M0tWemNGOUs4TERzdkNQTHlYd0FzbERIWDNEWVFtZnpVVW9HTDhFVHNsZGVRdzFJaHVaRnRncDhOLTM4a19ZcUxHMFJvWHB5TFlfYXVMN08yU0tVN3ZmSWtUbkFjSlI4M05Wb1JOQmc3c25oMU9Wc21hdWtBUHFmUEx1WmtvU2V3eTgxVExsZC1UTzQ4ZUNQeElVc0xtcXhtT0hBcWE1aHVnQUlVMGVTZEFneWRwNE53cjAyNE1vOUw4NjFKUVlQNkJpRTZIa2F3VW8zbThQMnZDQ0diWVI5WTN0LTZhQTZzam0wSDR4M2EtLWhwbWJIX2I5czNhcWhpSVR5MmloYzJWWnk1Wk82V2pwb0RBelRqWWJzaElCXzItVHZnd21VZzZHbVdGMUswd0VwTEw1cmdabklEYVdCTFFIZ0h2b3hPdnFIdkNPNTE4c2RXYmhGbF9YXzJ6ZHY4cUNjaVBjRnp6NG9RSEk4SkNyYmhDNDdBTlphZW04SUppS1JWWEw5eGNGRDZTQTg4M2x6czBlMzhIaHphZDUtcFBmdEVoZzJvT0NCYlVzenJkN1lyM2pCYVlZNU5pSnlMLUVlWFFMYUVCTlM5OEtYaHFZRnVIOGt0bkl4dFA5SkVnMTl0ZVNJbjlJS1U0cmoxRXNfa1pJWm5GcVBMN1l5OGpDS1oyclZfY2N0SFN3cDV5WGdpWGJxaUgtV1hyc0E1aUZDYWdzejFVVnZhY1Y1eXpCVVNJYWxDVWg4Y2JLMXVxajNLc09hRFhfcXBsMEdqckdsQ3VxSklUTjNqZHB5U3Vqc25GOTAzWS1mei1BVEotNjgtNVFyVUQtdHFlbV9mVXpSZE1aaFI0UGhNWFdtZ0MxeWd4TDdhckNqMmFoeEpGOFpKN0tkamtxTXdZUGVrbW1zUHJzSFZodVdZYVVxSjVXRlg1Vnp0VkhZSzZDTk5zOTVJYURUamc4LXJtQ2hyWDFxTnlpaF9NRUZ6U25DbG1WSjBCR3psRjVXQ01tZ3pyZTd6VHM4cWpBQmFpVGRBTWF5TDBpM04xd2JOQXpjQUY4ampFMVBjU1Z2RlVQbFVOaTdBN21McmR3Q05wSU5EQkkyd3RVdDhfTkpnSnluLUtuRFUxMFZTV191ajNNemtMckptenpXZ2lGbTZiTF9TM2pEVm1jUWZuZjZOSUlSbkxxVlhBbHBPWGVZcjZ5WUxuQUg3dVZ4cmVLOWRRS0xLLWlhelRkclJMb0JQUXFRZk1HbjRvczh0N0tUR3dCM05fRU1uYjYtUHNlUldpaENJMndDX210SEdnUVNIbXBYRkU2VVp5VFlhYmxvckRUVExwN2NzNVp4Ym5UdWVSb25Kc0IyN1V6X2puR1JqNUVMcnpyWm5VMjJhS1l2a0NLaEdpS1JwdnRiQ29OWGd0RmFxenNiYjZ4d29zNU5tamlRQkxpSnc4SDdYRGNzN0lHaDkwb3Y3aldyYzZ5QU9mczNXb1dDT05aWERveHZFc0FuZmJCRGhzUVBqTGNnRlM0V0dySjVQYXh6WDljc1B6R3Z0NlhRZVE3OVNEOEdMbkhjNVp6cVJXSC1acF9STjN2cmJXWXFkYzFXNlRrZnpHNU1jeTh0bFgwcV9qZGp1S0VoanliZG1ySE1ERHljQ1pwSnhhZ2d5dlBROE5MTU5MVjAzUlltZjdLWjNkVUYyQlVrMm1SRW1rZGljclJXeFJ3MkNfZDc1ZEFFdVQtQ0hlT3hOcWM2LUhodWx6aktmMEQweWtGbUxyelJNWXlUSVB0SllXUl92ZlhLcm1CdWt2bDJ5YjZRSHNfWXo0OFdoMVZBV3dMd0xRVlFIdTBSLTlIeUgycTk4MzBMT3RLb3BZanR1dXBic09faXNpMFR6YjYyWFc4dkNIOU9KanNkRTNyYW1nNFpvU0dBRVlvbW4zOFNfeUZIOWZHUWRBdHBRRHpfeUlDdmM0SE11b0JXYmpuaFEyX3hsUVk2OGxyR0VzMkphZEVVZVZnTm1RUmV0QmZCVDI2RnpDWXJzd0pjQkU3Nl9jMzMxdzlYZHV5b1RWUWl2V190TzNQeDZEeG1SMS0zT0kxMUhlcVpreVdzVTZ2amRUN0FUVEZvOUZ1bVBKQUdOSy14UW5OQzZnSVZsdmx5elpSLU13R2ZIVkNvRW1abGQyYWczcDlteUVWSWg4bGxsS1dBNTZuN1lUNFp3V1Bmal9FWE1JdW9zTXRwd0Nxbjh3cnJsWFZ6Zl9VR1dtUktVYU5fV3Fweldsd3MzUm1IRFBZanYxTnZ3TEM3Q2ZsZHdaa3Y5QUo1ZC1OQnJlRVdiZDNXRjFxSTB4NUJYbXUwU2EwSTJRRWw4Y1VZTFZTVlo5MDU0Q0c4WjFxVlVUV0pEbXNXQjVrdWJKM2JqNEVsekhzYVBwY3J5WDc0TnFwQTBTNm95SFBSWVJtb1ZkQnUzVm5WVXhIdkNoS1Z2VTdmS0ZtRzd0TkQ3LVlqYzRKWmJGUFBQc0NZTmR0WE9KWXpoM3RvYjY1MTNJYkVOMUhCaHo5RnVGMEt2NzVsdy1DYmFyejA4S2ZkODE0SkVYUUhtZWhfaHQwUE5wdDJ0cFQwUEM4akczSVpyRHpQbUxqcGlHQ0pVU1pFSzhnNGxJcXZaMFF6SXdMWFIxLVZmX250VG5DRld3cmYtVlltdDFpMHZxWkJFcXBUOUNMOGs4bTBLbm4tb2RwSldOTWttS3pubXUxWC1kVnN4V09IZXJnOVRONC16TkhRcVNOUktfRFdPS0RSWWFSWXY2VnlOOURjRk1Ud3dhRmVEVGlGRkdGX19KSFBsVTlhSjhENGdrc25NVWFKRW94TmVtYzBENGVXRVJZRnoxNEo1aGJIa3F5Wkpsd2wydi1ZVFBFRF9xY3h3RDF1RDlxOGx3aVhfeXhUc3hiNUVYam0zRHJXajlXRVh4UnZCRTZaNUNXWHdKa2VtczVkQ3RYdGM4MDRQR2trNnM3UHpGQ1Z4dVRVTUlDZV85WUt4c2lUbTV4QzNhSDN5dkVYc2ZOOXlJa240NFFCcGlCWkl6TnFENHpSMWZfWlNaRXJVSmJyQVJxMzRTUjdyRFpFdDlxU3VXcVh6c3JtaXJFSkYyRUQ3M3B0YktKdzFsa21zSHdEWTg4NC1aSVozZVUwRzFXTWNhRmpVaWtSS1VYa2VqOU5wNTI5MWdBSkNHRXB6NW5WZUNJaFRXdlhhOC11VHpRN1F6VEtIZDcwUHVsUkhTcUlyMXh2cndWWElCY2t6a3VXbGJLVENVaXNub3VBWWtEUVo1aGtaVWlHVXpBbXM5T1M2U3lteWxDa0o3emc2N2M3aDRHcmJNUEFacDk5T0JGdGo3UG94c1g4RDdKUVN0QUdiVEpWWUpqbnJoc0JnOD0=	t	2025-11-04 03:44:13.685399+00	2025-11-04 03:44:13.685403+00	\N	v1	["ESP8266WiFi", "WiFiClientSecureBearSSL", "PubSubClient", "ArduinoJson", "Adafruit_GFX", "Adafruit_ILI9341"]
\.


--
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.devices (id, name, description, device_id, type, status, attributes, last_online_at, created_at, updated_at) FROM stdin;
e7b6c38b-2845-4f28-b1b3-c86e90c4788f	加密烧录测试设备	用于测试加密烧录功能	encrypted-test-001	ESP8266	inactive	null	\N	2025-11-03 22:58:08.427087+00	2025-11-03 22:58:08.42709+00
8697991c-4de3-4a5c-9961-ba73acfb61f4	esp8266	\N	esp8266	ESP8266	offline	null	2025-11-06 19:28:23.988929+00	2025-11-03 02:25:09.009357+00	2025-11-12 22:30:21.280504+00
01d5838b-f778-460d-a32c-11d5bb4816c1	测试ESP8266设备	用于测试远程固件构建的设备	test-esp8266-001	ESP8266	inactive	null	\N	2025-11-04 04:23:36.554095+00	2025-11-04 04:23:36.554098+00
\.


--
-- Data for Name: firmware_builds; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.firmware_builds (id, device_id, firmware_path, firmware_hash, firmware_size, encrypted_firmware_path, encrypted_firmware_hash, build_type, encryption_key_id, status, error_message, created_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: monitoring_alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monitoring_alerts (id, device_id, rule_id, metrics_id, severity, message, status, created_at, acknowledged_at, acknowledged_by, resolved_at, resolved_by) FROM stdin;
\.


--
-- Data for Name: ota_update_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ota_update_tasks (id, device_id, firmware_build_id, firmware_url, firmware_version, firmware_hash, status, progress, error_message, started_at, completed_at, created_by, created_at, updated_at) FROM stdin;
6daed333-524d-45b5-b93e-de64607804b0	8697991c-4de3-4a5c-9961-ba73acfb61f4	\N	/api/v1/firmware/download/esp8266	\N	\N	pending	0%	\N	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-04 03:46:56.758576+00	2025-11-04 03:46:56.758579+00
1fe73716-7051-4c1c-8c58-196c3f94c083	01d5838b-f778-460d-a32c-11d5bb4816c1	\N	/api/v1/firmware/download/test-esp8266-001	\N	\N	pending	0%	\N	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-04 04:43:18.345284+00	2025-11-04 04:43:18.345289+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id, name, description, created_at) FROM stdin;
\.


--
-- Data for Name: security_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.security_audit_logs (id, log_type, actor_id, actor_type, target_id, target_type, action, status, ip_address, user_agent, details, created_at) FROM stdin;
\.


--
-- Data for Name: security_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.security_events (id, event_type, severity, source_ip, device_id, description, raw_data, handled, handler_id, handled_at, created_at) FROM stdin;
\.


--
-- Data for Name: server_certificates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.server_certificates (id, certificate, private_key, common_name, serial_number, issued_at, expires_at, revoked_at, revoke_reason, created_by, created_at, updated_at, is_active) FROM stdin;
833176f2-60e7-408c-8dad-80c54959b109	Z0FBQUFBQnBDWjRkcFJVNDUycmNfX0YtQThVdVhvV3JJbmhhR3JtMV9IRERqSHJqeWtOZ21PcnFjbFU5WHROSWlzWXIxTFBSa0VFUGRvQzJ2OWFVaU9aSG9MNE1fNUEyLXU5TDlqQW02dUp1YURoZ2xHVWJnTEY5aTNYTFRKazFZNHhSWVNHN1ltdjg3SGNFR3BsZzV5R3RQcmtQV3ctSl9lc1VrcnlhZW5pTmt3WWt3emJWb2ZGUEctYklLTGVPY3JuY0wwbEs4alVUWmNodjRVclZaOEh1Q2Y1RGJQS1hOaUMtRTdQTGtUc1NaaDF1YXhpRkRvRkRUajlITFJhMFVBa0FRTTZzNmZvUDIwZEtrUHVNTXpQbW5QYThjTDMyTDdKOXhkVjl5VWFPTGw1WlJZUjFWV0lJREN4RnZUS3V1QzNMS3V6aDZnQndjclpab2RmY01nalBhY3gzZDl6SFNXMzZ3YlhYMTZXeWx0clRRazlWXzUxbjdYT0Y4eWF5eUw1RFA5WG02dFBOalQ5NXBJcW1IOWxDTzctR0JwNTE3QnNjS3pwOFNlZkpPdlEzVF9DNGFmdHhSNm0wVTJJdzFnLWZoOTF3bE5ob3JaMFFxZXdIS2tDSWVra3pBblVzUXhHYmxjQllRR1BCOGV1bmxXbU15ZkNMRU80bHhTQ2hwOWptNlBUcWQzeGR5N0R5TkpLaFNfX2VlY2J1R05lMnpDWWdHNUcxcFU0SXJoT2x6ZzFaX2RRTTdjb282TDlwN3lKM3N5cXJnNG5wcDc3QmE4c3RyNFZUUmJBNHhmSVoxc2hBZXhub2dPOEdMdmNLS1dGNjNNVDBKclU0VkZyQzNyZ0ExX2pkTFhsVjJQZ3c1alhOLXRZMWc2RUFwTGZfY284Ym05S3dpMmpWN3NNTE9JdXJURXpvbnRrRzJNRW9KdVdNSUh1YzlVSEQyRmJ3Y3VzZm5XTWVnUkVhX2FoQ2lUUGdtTk9sSlRHNXNBZ2JZM0YxQUY5LUdrYXprYmEtb2hUV2VQY3l5Z3ZHOEJyQ3Z6WHdGeGFpb012eHJ4X0VNWnppYlB3YV9jMjlsZGN0ZThWTGtOdU40c0VZR2JwWEVWbVg1X1g0LVVpQUNHVmtIamRQWFRYbzRxWjVOQW5ySnZDSzVXMllScVY4SlVVVzZGZ24yWTBDZHkwWC1TME1zaEhTaHVmZDNoVEh0ZGJGbVJMaWZ1aHFGWHNzTjNpSFU3d3RyaktUSFNTdmNmV3Y0N1BXRm9WTWRZYU1YNkVQb2RVRC1PR2s4ZVJmd3hrdERIRkRXX3Z1MnMwMmk0ZXZBTlZyUXdPekxDNjd6ZWRpVjR4eE53UmtZVzdwT0U2eFBYaW1qZ3RCN3VTWDFLQkJfLUxaVDc0TUQyTFU0RWRmdGNBYjBUQkdOSUlJVjNXNlhiVS1DMlJmMEdSakRDTFRsM3hEVmFUOW1jeTFPVGcxamJvS1ZjTy1fZU5vOXh3dDAyQ1hTY0NoNmpUTVJkV1dGbE9jQk94dDlLeGJzX2h3Y25keEotWU04cnByZVlaMExFWDRkZ2Naai10WklrTmFYLVlFRTlmUFJGX0FDcENsaVhtSFhERjh4eHduczhOeUtabndFR0tYZVh5RExxWjF4Y2lHN2RVak9yVHZoYXdEcWJfNWdFVFVmcU9Gdnc5NEdkUzEwUVFZRE1EQ0syUk1EdkxQRldaUl9OcVRlY1NSS0k4YzgxWDRiQnBHUnUxbXFFb2k2QVNyMHlmX3pVSFY0dm1WZjJFRXBaVW1BWk5zVDdJc2xXR2V6MjB3MjZ3Wjl0enEtZ2ZZaExaYVU2SXBjNVFvaEdySThCUTh3NUluZDRsaHZJWU9NYlM1MWxQQ1pGWUNqU29iakQ0VUxkSWlHNDNXaUlkbWVsVjUzUW5aTmVZblhGM2ptT1NveGV3M2ROZlNISzRWdWs4a1NaSFVnQXM3SVFMQm5SeUM2eU8wZU80ODhLNzVVbEx5cnduSEEzbFczdWhSclhya3NCcUtXaXNVVUhTVExnSkpJelUtcXZqZFpLcF9SY3dsWHQtT1ZveXFQYTBCa0N3UG4xVHBVakxaLWd4OWJUNjNYUXVQcVRBNGRpV1A1WWJLS1F4OHNOczVEeVVwUXRVTVZmN0VvR1pWMElDOWJDS0N3VUZWRFlCWjhBRjRlbDNFLVpYZ19NZnJHWWNMdVliTXRTY3FFZDZHMzZKZVZDbzE1SlUzWGlhU1dyZjAtbDZNTnQ1YVhxYU9SRmJaVWtnWVZlN2J3d0dXRE41V21LNi1QZ0FieXIxbnJmbHZQcEw5SWNEWkpHWmhTMFh2OVExM3o4UWtPRFJGcEh2NDhpRUI3Z0JzN1FNc2pwT3k1S05FOUp6aWFPWVlFUndERDJNTDlIV2J4NnFTdXJ4dDhOekJpeWlwbUJhNm01SlFXblo4U0g2QUstQ2JOWFNvbUVDYXY4SXNEV1dGN1dQOVd0SVE=	Z0FBQUFBQnBDWjRkM1lhenJoZmo3N2hRcURaN3FPUE10eXhWckh3OVhzai1ZdzJJcDlvVjNNMG1yRGk1QU9xNHRnQ0xyd1ZMU0dCM3FzSXlySlUwd05uekVrQUhDMDl0Z1BveUFPdG5OZEdZVnJkYjdSYURoR0l1MC1IeFhJVzZ6TUlWVU9yYjhqLWJKaGhiemRvYVFsSzJ2OWlJVmxpMkFuaUxlOW9yZ3ZaelVCZUhFRlh2MFh4bGJhSG9hX2NRdHdoZlJ2RmVGeEdZelZiSmxTbWc3TU8weTVPaTFIaHVWU1lJbGk3ZEx6SVBHYVRHZkYtMDhJbjhGNWVuOXRuZFlLWjROSHRUbDZIUlZ2aFpFYVF4N1lKbEFxZTNQUnl0VVF0RjUtd2dJakV5djZ6ZWNpSXpteHlqOG16dkRsdUZYdmJaaXpVV1NPRmo4Ym1ORy0tWXExczYzcHFXNzlPeUoxejgtZUFfUHVJS0JONnYzMERKQm96MEdpMDNCWGtlQkVVbnFsNmhsbHJ4UFFrdVcySEFtMEl5T1B2TFBldllCUm1pdnIzTG5hbGY0a1ZhOWRZVjhlNWkxR29lVmtfZWRCZGN0V3NMbmJWSkRJUlVqcHZxSDdkVERkZ2Q0NEdqX1Ata19raXlNOXBPM0MtYkpXTFJNRy1MQVVLRUZKSFdtTHNOcWpSRlJSNlNsT1prSWJTUDJ6VF9iY3ktcXRYTnRBeEFSUWk3VWM4ZUtMQ1RhZlVHOGhFR1lEVFFpSnIwdGdyUC05RnF4RHpxdkt5cGdKMDdUR1I1UUhiUmJaNGUyVVpCRDNVQjctb09MVWdQMWFHMU1XN1F6MXpUN20tVDYydmZNS0R3WWJHSmxVcHBBbms0Q1lPSFhNUGJhOWl6ckdOQnY2QWxselZmckNyNmpJZE5yLV9BdWxNM1pjc3VqdWMxYnFFQlotNGRkWWpoSnAxQmhoem9Ga0diOWF3eXpqR1l3TDJVOEFEemd2a2ZFWXlreDF1RWQ1ZGtteVExYk1GVnEwR1ExZGlxdTluMm9HSTJMYmJPQ042YWZ4dC1pMl8tYlFWdDY0UVBJMVpqR201bXRIckV5cnpFb2V6a25JVy1pSGJRUHh3YVZRd0RqTFhEbkZQRU9YS09pb1oyeFJkQkItakRLMERmVU0waGxackhxbUhGRE1aVlZyU1ZROEhZX3pvZ21HNGNDMGZlWVhwajVEcWYxYUNqQzhkS1Z1aUZOejE5RmVtUFQzQkNwVklYYlVLc3pSY002WFNSdVlUbVhyVlJlZVYzQlZ3Y2J3QXV3RWwxa0ZTTGFWYTV5Y2ZxYmZvVDBZUXBQUG5OMi02N0F4TGdJbmFURHMyb2dpTWZkSDI5UWhIekdicC1IYlhYdDVjdnUwY1lLTW5oRWNBUTZqVHdZTXlBb3VqdkQ2Y0xXLTF0akdLUHNJWEtlU3BMOExZTm1Oc01VUDc2Vmg2UlN5XzhJRUNwZ1hSRmdYaGtoZEtubVVPQjNFZ0VLMk11anQwaFU4RjZUUUNDeGpzMUJuSUdpNWtvTzJRRFc2bURCSC1UV2ZlVDhTN2lVWGRhcWlGdmdVV1VzYi1SUEZrU0tIazkycUxjanBubEY4QUFKQ2V1eEJaZ1NJLWJWODE2V2xRSGpJb28ybUNlRlZPQzhTVV93Z2lVMjViUHUteW55UFBkZXJiSmlZWFFMUGZteFdHOHpTY05Ha0U4M0d2YUZMNWZ6UXBBd0dTdjVBVDRhTGFBRm5KaVM3c2R0RmMwbDB6OGtwdTNVQmw5akc5dkFNbXdxWExXc3pxT3ozVVE0Z3hqZVhOaDVMd2diNU16QWVkRmk3cmlUUDROaFNPNnY5bThxTlpXMUNFcXBMLXMyY2F2VXp4by00c2JITmRBMWN2TTdSUkMzUTJRMDAxU2FsTkxaXzFVRWJLTU5ZeFg5NXNoVEk3SzQzcXBtUHhvWW8wMndyUU5jakJYaTZZSF92VkRYemFyeEx6SVhvUUxPTjN3QU9zZWVjNE90TmpQQ01ZQ3RVZXR4NzdGT2tlUmhQUHlVd0hkSDk0OVdsRm1wdC1Fb29fRmh5eWdyT3p1VTJjRzdaZ05DMWpReWFSMXlLdFZHVnRXdTI1ajk2ZzM5WVI5dGx0dHNPOFVyemZnZUxqaXNTQ3d0X29QOTlySGpNNVZpV2dKZ09wN3RtUzFtSjBJa1VoWVVBSVBxTGFxUGRPS21vSDNvaTdrVElpcVRRZDFmUTl1TTdGdUM4Z3BTWjkzdHVBYWctYmlZam1UbWw5UENBbGR2X2R0TXZmaFljYU5CdHlOWFhQMW93TjRRZEZfOUVkZUdsNExMOEVCcXNuc1RLall2OThNZGd2VXMwYXNINVZNN2RjWHdJN3BUV1JoOVFocXBIczZnb0RGYkN3bVVmbHY2MjZqX0d6M2xuSkpPdWlhYWRCUThZcnRZZ3JzZWNnTm8wNWhrUDNMX3I3OUZ5WWgwcklLaVhjRi1PYlYwdDlqT1hlcFYxWUd5NTlWVmhTbEtOV3hnZUxIQklyTEZ6Z3pYZGhoQ2lYUzUtNjdydWhsZ21hQjM0ejBUUDF2SWMteFNaNENONnhveVZWRjdRQkdfclB6aUVQZUVCMkVLWjgwbWdWVnZEQmdwYUlhU2VKbjVYc1FGang3UDNUN3RpTU1KTTJlalVzQ3BYTDZ0Ynh2a1lveDNPU0pTTTlBYnRMRFI5VnowVS1QRVNRT3hmb0xxTl9hbzFCQ0NjbmcyMmg1OVhmc0dPWGJVelZaODFYYmVjN2lHMnkyeTNkbzFBWGJqVXZ3dVB2WDY2dXZodnZXSFM5bGRqWjdIS0p1R2NuOW8zU2JYemQyUExnRGJtVHk4UHJsWmRDajhzYklGQzF5elZsSFljVlRsMG9wb3dvTUttMW0zYlJaOEFhMU03MVZaSmpkaENCbVhmWk9KWkt5WFZ4cnVKamRYek4tc3VtcHRtakEtR2ZnTXhzWG9zUGVza0NhQzRCMkpmUHdpTUtxWGpHcjJ3SmtvbmFKUVhCQ0ctajBnYmF5N3ZNeG5ETjNjRndTVjBORVFFUUo4Zm12	mosquitto-broker	155278022791176656712631841161777658588636447279	2025-11-03 22:33:01.010448+00	2026-11-03 22:33:01.010448+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 22:33:01.028149+00	2025-11-03 22:58:08.607343+00	f
f97757e2-0972-43e4-98ff-00028b3b6e04	Z0FBQUFBQnBDYVFBb1lidWNsc2JRNnpGOWhJQjhWVFJwcEtlaXhfd3hqdFM3dl91TGJadHVrc2NoTFNMTWl0V1BRM2V1akZFTjJTMURHM0hub3dZNWhVSUFjZ3JYM3BtSkgxZXkzTHB4U0pSR2xyT2tZX3FEeWRpRVFkNnVrdGhTNHRERnJjeWJrbDdya3NfalRhMlpNTzRWVGI5TEthY2wzRUNvM3NJOGtSR2Faakc5bUNuQjlGNEpmNWtTaHNody1EYUUwbXBXZmpFQ09kRlg2bTF0OHFHcU9CWFpPdkNydG9zZXVYVjN5ajBVbzJ4RjBkeGh5b01UbEh2dWI2ejZOblRycDhjQ1kwbldNOHM4YnZ5VXlqdXNoSXM2WDU5Q2NlT25tbUpHZEVkN0R0NXBJcDEzdEZFclp3c2FQMVVDUkJGV1M1VHloT1JhRVI4VXdiU2xzbHUwT0VCNV9jaWVsUDF4UnVJOV9JZjJjXzhiaEE0cFFZaHp5X05RNnhIa0JsWnlPSEZ5akJnYk1PZHBCLVR4SXVTOGpwbWU3Z0c2NHI2dmpjQUNNV0FhTk5aY1g0azNrQVhTczdGa3BrY3kxSDZYclNXY0FHdld0YlY3NUFpOUxOSnNKcXFBbkxjcHRLT1pWenNILUMzRmRjVlJaMXZqejJlVnp5ZnZvUlVNcDFjM09iSjRkU1d0MERPaURaU2FCOUlCeGd1MERLbUQ5YWxXVnhrSmVOSzhfS2I0aXVsX21DTFI3Y281Zk5lMHlacUhmcWdIWDJsRkFiRENGZlE3TTJlZjBISERnVFpJRDNPLXZMOHBDNU9QeE56SVNDQktoMlpUdVNrdkh6M2F6aF9sQXZxOXFnSjh4bXhGM1JfQ2l4MWFlbzZXRXBzd1dsbXFNOERwWG5ZMlJmTGxQTUdHMENNbEh4RXE3NkcwTTc2cmVTa2h0Unh5SlRlb0prdXZLNUxLQnlOak45c1pkVHJlbmo5RUF6RURhMF91UEtFWlhKbG96bi1MLWJ4b3BDZ3dUT3pNMVdwVlBRWUxTVV9lRjJxT1FKNlNBTDlhcVJyWmdFWVhsLTlVLVZkZnRXazBSSGNZbUlMMVhabGMwdzcwdGoxSmlSeHR1VDFtZFI0aTdnNVo0V1N5MXhsWkpZNnFnMEwzWTlsNDBjRTMtSGlJOUpRQ0FFb0UtNGg2OXRuQnU4N3RMQi1UYi1naXEzMk1KWFg5X2QzaXlWWExxaHJaMm5zUXFWOFBwbHJrVG1RMkQ2QWlTeDRMbC1OVlNUREEwN2dHSW40WTNCa2hVWUpaTHZHVklrV1NoUzRkdWtWTmZDZF9GQmlucGZXbGU3OUI0dG1CZ21ENVdYUks5OWF5VVB5aHRKTUZuWGlYYjBYTXpGbHBVaThOMkdydjdLT2xhTFFrREtqeDBwTzlpTVdsemZ3Q2NXOGNCVFBTZ2h0SmpDaE90elFqQXktLWUwWGpyakpJREl3elNwY0FFQmtxMGRMakhTZGZHQzNzV3paZ2phTnJtaEdZYkU2a08xd1M3MkRxUUJPX0ZLeUdWSnVOdldTSE9zRWdyYXNwV2I0aUU2TmEwVnJsNS0xZ1dxQVJ6ZUEtYWdSdDBwTmZYWFJENWZoeGtMTy1SRzZWOUxOTnJqNVpoTi1jaDNucnQtak91WEJQcDN6RGJiU3BxSjhNeGVVM0ZIazZRNFhLYW80YV9EY3FoQ0w4ZDY1OXJDTnRQbXZCSnczR1k1ZUFHWmRxOTlzZ2hJQk1wRGVld0oxLUZxX0tzUmxNWEpTbnRRY19iUWd2ZDhzZ1MwYTQ0LWN1cWVKbU56RmtYOTdIcGtQRVB6VVNWdW5NMkNvY3VoQzVTOTlURXVyWlpfUWFUcHZmUDhGbVh3bFo2MEJXMHZxcWJCalFJRkJFeWJ4a3dKekYxMDdDOHE1Um9JYXZXT0VxWXFpMGdyY2Y4MU44aXduOTZ0RVIwTGdJcC1YNlFtcS1nLW5BdHZIS0M4T042VXlfM014YldDWmV2SDJBZU9pczNkYUJjTUpjSmlpUnNITVRHclIzZzgtRkxBYUJWMi13Zmh6bXMzNlRVcTZscl9OTXlrTHlEcE5hb2QwS1RRUm94V181TTY4SWFiTWlLcDZRRkFnQzQzRkd2WDBhbGZkeXVxVzdxYkhjRFAtRk03eW5iMnZGMXAzYkhEX3FpQWpSSk5UeDdPZXhTd0VxMWVEcGR0VnBDSnhMN1hoeUlYUnZfNEZrVTBDWnpSbElSZ2tib190MlhwTTNOY1RPMmI4Q2RHZHVhT3FCRV8wQmt4T2dBd3NVUlBZZGIydUhMM0NtaGFXczZOTjMzdnByWWk5M3NYaWEwQzE1aVktSERaZDJxem5nekJPalFPb1RnLTZQUGpRZDF5cmZSVVkzUkZ4Wmcydi12dHJrdW1SeS15VE1sYWY5UDJWT19yeFBpNDZ3b2c9	Z0FBQUFBQnBDYVFBZVREak1tX1BqakEyU05mSU9ScXVERmtVWWlOT0dQOXlKTWd0eEJ2emRSLXpBMkU1V3ZhQ0hSSkNzRXpqWmotR2pMenB1U3k4UDBROFpsblF4d0hNeWI1NGVtYzdwcERqYUZ4Rm9LQjQ0bEF1UDF5ZDgtdE1qTTgtT0pmcnhtcXNjQlF2MmNiQUlqWWwzUU1aNGwyb2xRMkhZa0pmUmhkaERNQmEzNlNrb09FTTlXWG5YcmttQkxEU0h6bEd6Q2ZXbU1NakFJYjFfNFNXOTBuRVdWQWdHUE9pV3N6Ni0yV0FBb293QlJFTHhuSEszYnZDV18tNFlZZVNLZVlSVWdOamZtTEdHeHBVVzVLVm5DQnNjZFlpRmh1Zl9CcmY1ZXVyakVWb3A5SVhYWldWVEtlZHNidVdpYWx6cld5SjE2ZE45VlBKN0NfdzNCZ2I1VW8xOGktcHo0Z2xrRGxlOW1oWjVfTW05NmZwY21zcHFYRHBjaTY2bExLLTBvX1FBNGFtSmFlVkZrUmpwMzQxcVJSQWhuUnM1TC1ONE9XdDJDb1NKeXFyT0stTjlzNjJXM2VHRGl1UlRUTnBPdExXY0dCN3hab1pUck1TX0FJNEY1RUVsNFBzYWhuSnhZdFFUOFd2aXpacWE3bzhiaFZjcnZVZzdSRG5TUFdGREJCQzJlZl9tOTBjQWZVZ2dsM3ZuckdhRW1BeGt1UHhMM2taVXZXQjRsUVZWUjM1aTBYR3FVNGg5Y250c1p6aXhKdTNTRjREcE00dU1fenhkRUlxX2dfeDdaNzdhQTlnYklQM0dqYTIySmJpU2dDMUhfa3Zaa29MWFhTYmVsaVdlelQ1ZmdxTUhXMVJwZlNRMEhkbE5LSzdpQTRpaUszWXE5SUFXSmRQVXBhZTdsVFpHU0pmNHNkRUZyb2thZnRndkhkZm9ZSTNudlF4QVBGRTRabUktU1BfNk00VmlRZkJyQmxsQ0VHWnVFakE5QTdUV1ROYVZOM1FzWXFvTHU4U0pLdG9zZzZoUGRHX2V5MVlyUTNKVllkUWlVYXJVN2hwLVlZNGE3YllZYk1kSXVsRkIwbzdBMFYzQ3EtNnhreUhtZHNBbWI1VXdfdE9uNy0weEYxNEVDR3lub3hhR1RvM0F4VXZYWDZMdW1PNHUzb1pJR0o4X3N0aVdDMXBMN2FhSGRUZ0p3LXBJal8wTnptdVRVYm1vUk5GTGw2TjIxU2dKWHM0Q1BQNThUVzdIVlp0R2xQcl80ZF9FVHBYeVZLTDZHSklLWi03ZUZudTJSXzRfanRQRHBSZVJJNzhFVDlvMFdPcFBMSmVrd3lFbHg0eFBpcl8xb2psTEliZ0FMM3dYcmV0anQ5UzYydlA1UEM1WGNNUHBJUVhHbGJJYlMwenNVNEVCRUtEY2U3UDJrU2FodzkzUnotZkdZNlM5cDlRQVVCYV9rZUNablR3TWFrS2dSazFUUmsxZ0tQekRJUWFsWlRVMEdhSS1FVVFOcmQzT1ZhbWpDSmhza1BUZDJpOXpUbkRYQ3FMb0hmMEM0MkEtaHpxWkVuZy1kRk8yS0VqZXRCdzEwWmtWMjVpSUtwWmdXQTRFVzl0dVQzOGVfdWVhV2JtdjdjTlFQMHZXZGQ4Rkc5N0JPelVvUU1PUlo2N2NHMVo3a2hkTnJVQ2pPR1VOX0dJQldBdVdaaGhqWk1qM01QdFd1ZTg3N1RMQXNwbEpiLTdadHB3YWRmaHZCb3hNaUxEc2VSMjFBUVdHa3ZtbmRGcTdJd0hnV2xYSHFNbkMwQmRsREp5VVFkeTN0NTM0c3RVdFAxNWtudVp3WU9udDZpaHVpQklvZlRWT2Z5clpYcXptclRLc3ZFRVRKV29sY05taWlhV01qS0lDNlFxa0I3TmxtdHkwX3M0bXBkZ3hZNUd4bU5aTVpnQmxfM3I1a0VEV2pJQmNyQWZsZW1RZ3NNR3RPc3ZsY1l2N3RlWlBMRzlwbmFPX0FqV21QUVBRWXZyTFJzSXdIczJmWHpRdU1SNFhTNXhMWWlwYWJOaVFoYVZlTDFnZF9iSEVjNUw2eTQ0SzlMWDRSNWhwWFNQT0hlNWNULThFUGpVRXhuRFYzOXpSTEFkNUxsenotNG51RWJLUWxxeEF3ZTZ2di1vNkIxLXIta1ludnZMdkRPbzBuWm5HeEhNcERWXy04RUFnTzFEWjVjZ0lVUTNjNHV6WURWeU9fRXViZzBPUTZUWjVZbldvc3BQZFViZXQ2QkRZcFNEb1VMU3RkU2FvQlRVQ0RxTGlsZWVfd25xRTZUcS0yUjZRUkNzdmFCYURpZXEyRE1mVVBzWFh5blJjb2tndWtXYk9LN01zNzVIVUtNZ1JzVFBaS2c0NEZJc0FhRlBLUjVvdHF6TFZMOWFVZFpfUGxWYWpSdDg3aHhIb1A0cnZCNHE4V09BaDc2XzNZLUdnV3RqaVdrU3FpZERWN1ZjaFp1Ml9vLVpTRlhCLTcxRmR4LVEyRXRiRUh3NjlzSmt0dGlCMFFORjVjSGxReGlEWU1McDVfcXZVNlVvaXJoRkZ2MGhOeUNDMk5KSjFYWWlDT3l2WEgzcHdnc1JBZFAzOHU4bk5EekNtbk4zbXRzcjNxWFEzQVRkS2dQR2pYRV9oelhIRU1LYktBUTRfaEhLamVjdnNOOGwzXzlBcUtWM0tDYlRDMm5JckpEQmtrbEVUV2Y2QU1wRGNHc2RvZ1JWcTdxQl9aelVOblQyc2FKN1IxN0lsb1ZiWUhNNldUTTlCbzlaMEgtQXhQeTNRLThXY0tJdDJZRHVDTFJHbFktUGZiR3Zwemc3OXkzZTRyd0VxMFk4Y3VaTE5NODR5OERNLUJUT3JoRWhFNnIyQk1iQU5LMENQZGp6a2xJNUUtdHg1bVoteGwwQllpSElkSlJNbWl4RjRTaDhTYm9oUGVXdUtzV1lwRllabXE2RmtaVVMxVjQ4ZkFyN2ExRmw4b0pBbUNMcmgyVklkQWZLdlM1NW9QaUhRZEJOT09TOF9PaUx2OVFZZjhpUk41Nm5teTI5UVZfa3NqdmJtTm1BS2FmXzdYMWwwT1By	mqtt-broker	71769438485991288142726680043957694402436987765	2025-11-03 22:58:08.617896+00	2026-11-03 22:58:08.617896+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 22:58:08.636795+00	2025-11-03 22:59:20.401165+00	f
7b605638-a845-4d8d-b683-1195f6f235a9	Z0FBQUFBQnBDYVJJQ19ITUJ4dXZDNE5DTDR6RFhjOUdxSF9mRUZDSUEwTFg3NDgyc0JWVGo2Y2tIZkxCVUVsWG5qSXZlSzJiRThlQVBxdndZaWdXSVFFNS0xWUk5UzRCRHNUZVBrRlNtS01XcDZ0V3pmdml2a0pCQjc0aHVVbzNrOFBUb3BxMjB6N0dTLV8xT1FDZnRmTDM2Sk1CZkRZcEV3Z1lxM3lBb3E0SFNWSjYzeG9qQjl0alI4bTk4TDVfWmZhS3ZQa2FuWUdDMWdFdmtET1lhWXZTOVhpWE5KdHk2SGNUWkJvQlRqb241YnBORVVFRXNoQjZJUVJBRlNwdTlDTWlzV3pCV3NNSUtKYjhOZk5wMHVQWjFhWm1GWERNZUp1cHFpU1JFYXBEcVdQNDJLdVN4ZllOWGpnRHNMXzV1eW5sbnc3eVh0NndrcFlpSU1sTVJkOFByZV9fT1dXdjhEV1ZfMjNySkxmaEVMY252dFZsT1VGRllzZmRXZVlJdl9zaVNJekhSRGNSR3hRRjhwTm10bXFsYm1kZDMxMk15VkRBbHFUSVpTTTFtWE9yZE9vWXdEejhwb1BDWUVNZFI0Sk0xZk1yMW9aV2d6ci1YVFJlYkVHWWZaNURNSElQSVByclNkNW90SmdFYmIzaGZ4V3ZRSll4UGFSeVh1TXBEV0UycVoySFhZNVZPbmlfZ3dLRnJsT1dVdnQtODh4N3VKX2tmSnRGT0wxVjRGVEJDWTZqbjhoZlAyQ2hKVnZ1QTlvMDZ1YW1nNmJMcVRDSjNzQUF2MmNDNXRLVjgydGpwajFDNloxdkNVdFR1WUFTcWlBZ3JBNWwtZy01WWZTSVBqT0hjd0JhSEM3LVo2RUFicW9ucFZyRTJNUkVfOWY0NnFzSVp3SHQxdFBWUFBMYnJTRU9WY0JIdXotX2pKZVh0ZVNTMWlrUE5oU2Vud0hrcDM0akJCTWxEbWpZOTRmV0NiTnh6RFhfYUpBMXVkSGVMdnpxM1JHZ090OFFvcWV0bDc0NHM2N0F3djdVQ3BQVlNDNU9ETU5LZk56RWxEUlFWM1ZlSmcyT1QzODlxeUNwX05tQ0dnaFZFNTFVOXVvSWp6RFJQbVZaQzVqeVVkVUszbzg2OV9ZaEJmWnZTTGlZTXJRa1M0cEJkY3E0M2ZtVjEzZUt3ajZscm1uLWRnR3JUREZabnV3OVZWYlZNVmxEOUc1QzMtNlV6SXFhaWJrX0ZwUUNIUU92Z1pMWTdkTnFGS2xfamowbEN4STdQRnNFRFItZTAzM3lpVjdPMHZ2RFh2dzZuNGpXeDd3Qk5TdEU5THc2Z2JjT0NPN1hRLXdOU3RUY1NaUVIxMksyVVlvbzM2cmswTlQ2MWRpU21DWUd6TERSY1VBeE5JOHJjM2psaFVBM3ljZUlXV0EtNDMyOHZPZ1NRdVNjQlByd2JuTk5FNTBhb0VqMWRrWDhSRHVwd0YzTmx6MDVCSXJSNFJLMGdncUswSEtCTDM0WmNIZ0Y4Z0JnMnpSa2Y4OWZMaFBoWkR4MG5wMEtjMW1HdGxpTUJ4RS1jcTJzc0FTV2I3UlhPZzZPRW1MSVc3ODB2QXJacVU0Q0M0Mm5kbVc5X21mWE5qa01CazFpTGZXT0hHSFJoQmFIZUUxWWVGQi1Rc1h0dFhsWGNYQUQtWVc5MERhSmRxOUdpanBFYzZJUGt3NFhUeFJlWE1HTXhMRDhnMEp4bUwwRndFNkxqVmU1TmFrMlBkZzN0YVZ6WEp5dGxKd2VJMVpIeWlzQk9XN2kwSjk5LTNJZ01BSzdWM2otaWJZYkZqVHI4NUI3ZmxBc00yWE82SUJNRncwWGp5ejZ4ZFlOUHM3dTMtV1lXaXpPSFVZWGM2TllRTFpERlpDUWQwZUF0d19PY3ExWEJxUHFkR0YyZGFMcjYyd2M1bHdUOXhLLUdGYzFGTG1jR2FLRUtJSEFUdFRxdElvY0NDQ1ZGckpQRGlrWDR6UnFPTENfQXl3Sm9nWmZNbzNlQ052OERMYkJiNGdMc1NhSUVmNWZvWXNnZy1IMDRMU3htN1JpZTVxYnIzWWVVSlJtc0tZRm83M1VtbkxqWkJycEU3emlsTU95dTNQZk5pVDBidkdUQ3N4cHV2R0dMZklxRklPWHNFZkh3YlMwZlBTZFhHaGdkdllDOUhYTUlQUWZvNnJWQi03bW10QjVaeHIzdGR5amFiTGNqcGp2d0ExY3gxWE5WNDlFU1hTREpORWhVWmtNQjJOd3BDTHpKbU10X05HNzZRbzNVc2VmOXpkRUNqU3U0V3RZa1djUTFZcnRQTWRYd3E5UU5rdjZ3RzYxbWNndjZQUXB5bkJhTENvNnVSYUd5VXJiT0V4VWFHVVJ5OFBnRkFDeEJyek9ReWM0SnNyZUhXaGRUVTJNZkJwaEl1NGN6SUFHTXZGV3lIMlA2dzF4YjFVYVFfa1ZEcEdZTG5WSkdDSmhuR1dHVWc4b3M1MDdlRXRtVS1IREV3cnI1aE50V3pXNGFmQ19BX1JxbUtsSkNGcXhxa21UclBVPQ==	Z0FBQUFBQnBDYVJJdGVPdzVVRHNXM09LT0NpQmM1VVJVNUxHVndyVWhTMGRhM2haS01NQ1BGdmk4R09tN3FENmt0T0FBUm1BZ3V4SjMySHF5THo2Z2VKYVJLSk96OW5vV1FOYlBXZC1ld2c1ekJXd0VuUXp4UXZjOGk1ZHpMYV9teGFMVlRlMVQydktkTUxDdnViMzc3eWJNNlhPY3NzUzBOOVhuUGJOOHVWOEdIMzZ2eGFXRWpsUGlXQ2dZNDBmZjQ1VkVUc3AxVnU5dEk3blBfS01id0NyeEVjWmRjUlp5emJMdHpRaW41dEd3RlZpR0xDS19wR01pdzQ1SmtjUnZMUXpSMWFMQnQtbU16MnFEZnY3a3pQQ20tMU42LVJZOEM1ZWNNWjFNV01TNklPT0NESTQwd0I2UHpVQXotQ25SUVVhWW9PbDM3MnpYN1U5YzZ1SVZIZG8tb1ozb3NBR3AydGh6Ty1yYnIyNUxrdkR4elBHc2VIdk1xd1NfaE1JODJBX2w0NHgteDdzUDhoQzhJZVhaejM0ZTc0ckVLNEZyUGdTMDNYd2JwQUJlRXhqdFRnX0NEUmZ4NkU3M1YtMjBRcDE3ZVpobHRheDNVU1Bfd05Ednl6NVpmdnV1dHcyN24xQ1dybGVjcFJ1eWUwaENsLUlfb0lfZzctaF96Q2E1MDJlRHJGRW1VRHNfb0t2LVZqdkpNcFdRelpQTkx4ZDVld1lJbjdUNE9PSEVmeGR3dHNhTmhhY3R2N1RFVFl4cWdfMGIzaEV0N01idU5XZENTb1RsbDRkdzNtVnowcWJTSHRLZ19nc2M3NU40T1VmdnYzc0JFSVpncTV6N3drNS1FY0J1NWhOcGs1VS1ZLVVrdlgzWlpaV2lDNmxPYVlNN3kxb1lJd2c4Qm9BdjJQZGpiVG0zUDNNN1QyRDMxZEpTT3NDT1VXQ0lHdFlpMlAwZnZoT21JNDI2OVUzd015WTBkby1jb2xmcEJFbVBDeHpyVjY5S0tJZ2cxTTZmTEo0OGJIaEdHbHdhS050SmtBZnNZNVJ0NnZJTDZqOThDRjNfU3NaRTB0RU9sZ0IzbzhJNzRWdjdINktkNXBOa3duNjdfWEs5X2NYTmVGbnAxZ25FRHJTU0hBeGhmV29ZYVlTTFZuR2VlU0lLbmgxalM2Rk5CYmNpRTRURjVsQTNfNzE4UnY3ZHVIWGE4cHVVTmgxZ0NRbmw4a19UTFNsRGpVdGx3VW9qbDFBVUJQZUdRNUoyRFZja3ctd2cyYTNXNFBqN290NXlrZVYxa3V2UUYzQUExU2xVbTAtWlNDSmV1aDZrUW5SMkRxdW0wbTJybk1PenVZRk5VRjd3MW1HM1VZZGFZc1haNFltQjdaSWo1YXY2dFVvWDQycEc3Ym9qdXkyQm5BMEhheFNQYUo0eXh2XzRJUWR2OTRDYWpxUW5JMUctQXlyYUNnS0RrYVRiTlgwSkowYm9wbnhGTFFjdmJFSkRXV1ZfM2c0eHhBdVVqcHN3Zldfc2hxUTZvb3d2U3NOSURtM1h0QTUtZ3BrVXlIR0xSUXhvcDdhYWptTjA5OUVUTmJvUFdya1kwVGtzWHZCSzhJR2p0Nk5VWkswbjNmVnBueUtUaWlsTmlOQm4wekZpbVRhUDZVczllbURwNmZDbE1HMERLZnZCVzNBdnVueXY2Nk9HNjRxUWgtMUhnRV9ENVBqVU9QRF83c2RpaE1XSm9qZU5kaGpUWGFqTmpNWHROUmdrZVBLYUxKMlhBX2U4X2tfOHlaV2lKT1lYQVg4Y1Y1ZDRHUWZVcU1fLU5pRzYzdmRIYUF3X2xSbThha1I3cHlGem9WcHhfM3hiak5ac2JKTW84bHE3cldJZE9lMmtkdjFrWWRpZW9IRUpnSFFiNXQwZUZxa212Ni0tRVFGZ2lneHl5c2M3LUR2SXVaN2EwQTRaNGJVNUgyTXdhRUJRN1VLa0lDVVhvWVlldllodUpPcXhNbHhWaWpjeWZ1Yldwa3paZjBBMlViWm1BS3JuamhDN1lSOWRhb3lMVEpCRVB3MU9WRXFLajBrTEpFbHBEWGs1VjJxa3Nvb1hWWjhwaFRiTHRnMVAtYkpFVGZvemg4b1NDR0pBbDhkNVpZYms2Nlk1dTJVOHZkYUFBTG1QUVl1VzNxQVotNW4tbmdLZ0R1NlcyaHBvUGZXZnVOcVRXSjVjendFSFdHUEdpY2dZWFJZXzdrSE9rWGJnRC1CQWZRa042N2w2Q0haRlJuREdaaTF5dWNkSEd4bDZ3QW43bFBTX25HRC1CZlF1cWtfU0FZYldvMnprYzhPQkkzV1JQYlkyZmpROXZPOGtpaVhtQ2JiS0tMX1RkeEpwbjl3UExoUGQ1SF91VTBpT3h4dGZCQVVVQnc2YV9iX2tGTGIwSFdubWVqSHFaUTVreUVxT3ZRM3V1OTh6dUQ3MUdEXzJ4eWlXdzQ0ak1UYVgzbEtNNEN0UnBxb2lPV21aWmJGUU45dDJVQUlQMDNaYVBQM0ZKZEF4X0hVNjJMdF9RRFZYTTNieTJTNTVWVGlkdk0yZjVTc2doMkdBbjh5VXcxME5EemY1bkV0M2tTZ25NXzIyRG9rUm92WXZndUJhbDdEanZKRzBuQXpPR3pzRTAxdUpLakFVVWlhelRqVVZNR0dOMnNlLUVEWTBsVkNvVVAyc0xHbk9Fb2ViMkMwOUZtMVBKdVhEc2dWVlF2OFFHTzNUSS1HNVFqZWx6UDFQN2VObWQ2UHV4M3d1TTlMaThUX0hFNGVTVHhBS29KNEFjSnNzNFMtaFJzUHlxVDZRRkxHVFRhRVVhODdpaW1qSVdnd1lGdVZjWWlfdVYzMVdzcnhtSU9GZTVGbHRxa2RiaFJoaHNhS3UzZ3N6V242QkRQU0R0cEVpYjRLTlEwanlyNy1RWmJSZDlVN0lzVGRpb0lwYmstNEdqaTdoRjFTemtEUDFheHFKRU1YaTFOVWdmdjhWLXhVMjkxLVZJdHMtMW0xQUVacEU5SnBoRHR5VWUyTE9saXBXUGV4ZVBsSHl1VmJiclRJVVY5Y3k0RWxiVG9TclVTdVNZTndnR1Rm	192.168.1.8	335038890977746040401692916642587434106168279794	2025-11-03 22:59:20.408737+00	2026-11-03 22:59:20.408737+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 22:59:20.426158+00	2025-11-03 23:01:39.920442+00	f
55ef721d-1200-43be-872e-e183907c244e	Z0FBQUFBQnBDYVRUYUVsS2plSEszb0duQnE0UnZ3R3UxM2o2THVFMkVub3dLUjd2VG9tOGlkbnBLQVdWQksyQmZ0ZGtxU3NCd183dng2aXV1enJRSnkwdC1vZlA5TzRwVUVJZjl0dndJOTZOOHh6SVBkdURrOGxORFN1YzNVdmN0b1M2X1h5cFNSbU80LVVfbmdzZC1uQzZPZkRabFVvWlYzVTNpY3hDb2NXYzdfMXFQSFZXNlhWemZmVjdGZldaeC1IOGNNbDVIem81RXR4Nng3SzhLZVpmc0RyWGxWdVNZQldiMjdqbFVfVEFDb2F3WFphRW9Pdk5aMFRVRndleEV3VzFFY29lS0dQUVFwZDhYWENXOTI1VVE1QUNpN1A3UERhdFFyZGdZSjFmZGx0dzNZQTlNZkl1dEVKOEdqdVhhLWZ3eHhxUS1feUdTaHU1YWdMVlYzZDZ2VEYyelcwRHNFbFp1TmhfcXgxbV9wVDNuMDBwTHMtV0xqZDF0YWRfVXhucnB2S0JaU0pQaklRbU41YUZyaHFaTjVEaHVBaWRCaUpnZTl2ZVZjLUtUUmh3MExDbnF6ek0xNVlLa0dGQ1BRUk5XWGpQZFRGcmhGanYtWVRtcE5BMzlpMUdycXYxUmUyaTN6VkJkLW5BM0hmdnVNSi1kcHFPRDlsWHI3UjNKRERPS2F0bzduUGNjR3lKRFV1UjFSazFXS0tQNWhFRF91NzBxWHRnSFVyMWd5TE1iYnZkMmNtRzM5SmlTTi10eVpNcWxwSzVHemZYZktmTlAwRUh3UlZkWC1jSWt1LTRaZlRGM0h3N2FoWTZuLVZSUkctTFFFVkFUYlc0bzJKY3ZULWFiQ0ZjcjdCWjh2Nmx1MHNhdGJfXzVlNWs4dnFjNHpFcWh6Z2lQQXBnUnlOMlYyZUNWYThYWEg4ODNTTE05aEwzcVlEOUdQdjJuaWhuc2Y4azQzTWVXZm9xcTFIS2pNMHRxZFdxb3hJQWUzYTBjZTVVZTA4cGVqeGdlSURaMnVpRmtkelJlOEYzWW0tdEZHZ05FYW9RcWRkLVBTdmw3Qk9KR1RERm40X0ljVU5OcEYyUW1UVnpJRkFuRlc4T1dnNWRvWjNjZ3k4TmRvWnRjVG1Rd09wZjJxRm9oMmVFR1JFcmRfRDVkd1QySUVmOVpOeXYyN0xoYk5xTjdNajkyWjV0eG1mS3QydUd2UmVsanRyRUZzczhwSGF5ZGJDU1ZJWWJxdEluVkVXMnlnTEZidlRhS0Z0V3ktekYwTGY2NG9UR21sUUFoakJTZEZfNGlxZE1SY1JzTFltMjBUZlpwdXJWU3dxMTlXN19VQWdlTWJ2MVVkaHRwV3ZOaXhkNW1jWmtFcDZqWGZvbkdUdnZQbUdQN01fa2JfQzNtM1hzRFc1dzQ5UEVrXzY2VkN5Q1BGdThlaUpNVU5GMXFkUzNTczVZd1NrNzdUcThqUXpJS1E5NjhzVzB2UF91SjhjQ244THFHOVdoQUhjM0h2RFlMQTFPTURnNEN4NUgzLWl3ZHBPS3VUNTg3ZjZzYnVjVEpXcTlhRUFjY2lkV21ORTM2RXB1YTlSd19KQlEwemNkMUw5TDRGOVlDY1JuYkd3WV9CZHFrOElxQVJNWU05eVZFX1VPSURjTnhoME10U2xDdXlKTmlDNEFUMFpmVENGR3FidmlNNGF6WG1WaHJBanVsMld6NEs1LUhKNzlpMnhSYUdOaHhqY1RXZWt4SXY1cmxIdThmMF9sQi1UZ1hhLUNyNk00aTJDNUNSMlNWUDZVanRCT3N5S2lfR3gzV0cwdkk4UTM2cDRXWlU3ek5fQnlsem5rbWxQNHZTNW9ZcERMZGM0M1d6Q3p0RFZJZVFFVlRpdVM1SFVfS1M3OXBwVzhkXzFxQ3A0dXhGYXluNHN3RGNrVVZrOXlFR3JZNEpzSnVlMldUZHNRMWZUeGtFb0o1djR3TzRuaW5TNVEwYzMxZXJ5QjcxRFo2ZmRZdFpYc25EYUdzb3EyTFBBUVhlMUdXSk16eDdzRFd4WlAzZFROekhUY0Iwdkg5VUJEYjFPLU9VN3dHc2VZQ3dDNXU2NGplbEp3azBHeFJsYTZFeHBKQWlfN00tZkdzZldJUG1lUm5aZ2hwSFQ3M1oxV205UEZjQy1ZZEEwSktPbDZGMnVVNzR5aXRxRldydDBYeVdKclBBRWxuLU11MWc3R2daSkVXN255dWppNTdCdFVHaTQ5MlhGWEZVb3pYd2xMVmNhblhBUWJfbDF4Y0FCNjB5MG1MWWhzemdoZzlxem9UZ2RIdnVBdGxZV1hETTkyNUZhY3huUXpSb0NxN3dOT085RE5Qc3Brc0lGOVBmbDJRZVgyY0pyZEhFUndqUzVEejhUUzB1ZUhRMWo2bThKMjVJVUlnX2RkUEJrNVBweXRzZVZjYTJCTzhfa1pXcjdNMTRSbGE4VTd6S1Y1aFVRZ1lZaVNkcmRlTGxtLTc1N05KaWFOM05rQms0QV9YUER4ZFVMaWdkMWZCbXhoRzN5ZmNsYTBZdTNXdE1nPQ==	Z0FBQUFBQnBDYVRUTUZIU1drUjZ6WjVTbFRHRW02NzhNaFVjVHhmOGdOaExRcGF1MHA4Wk5wQVlUS3lqTlNoM2tQam9FSkdTaGZ3S3JWN2Z1dlZwaXpYdUU5VGZmNnBIMUFyV3d4VDI0eGFJSlZHS0kxMGwxTGlrdlZFQ3pLNUxmQVdKYmVCekJNWTZqNGRjV0NZX1NTMFB6UllrSFBtdDhrRExncHdxMkt1TWppUE9KMUVRNks4akRiRkxiQ21wWTJmYTI2cC13dy05NW9zSWdIODFnX3ZXUnNaQ1N0bmhwc0hFYUZTVTRsMXJqVlVlWWZCSGlwZnRoV2VoZ0FRRU1mcWFUeV85QkZ1NnVGRU1Zai1TanJwZnJkeHNHUldoSmI2d0VlYUNjYVF3Wk5PQVN4MHJlXzZudEl1RTFldjZYeVlzUWdjbjFmdEIyZjhPMkVmYlA2RHFsQkpqYWp4TXdrbnpwMjdQQVZOeHNOcUhMeE1tbVl0bWhSQnE1MGZoRHdHMW03Q01vOFd1eU9OZzBzaWNTaWVLOGhTWU0zTG8tdnFmX2NSTmVZcWEtQzJYQlowdjlDdXVIQTdDSEhabmFReHl3d1pCdTNnWlZfVWRqZU01NU1uRVpyVXYtU3lyaDhUTEpyLS12WHBhbEFCeDZtdVVZejUzdzRIV2N0dnhORXNwQ3dDN0JjOWx5eWc0d3Fodmp2b2lMeG1VX2IzNVRZZklYMHA1Q0ZQQ1IxUXcwRGY3Vlp5VjRLVEdNOHZSZXZmMkliT1Q5cmFXVk9fOHBZdUswaEsxNHdvV2ZVQ3VtN1FoWDFPeWR3Tk5oUkRnYUx2TjRlVnZCeHZ1ejVqQUVnQXBTYTE4WWozTFFQZjBZYUwwTFBXLWx3TmxzMmFSaUFVREJ4d1VrVHVIaDJkc1NrZnNnOUNmTXBQcE82ZmRIcEo0TkV6d0MtRVZKTGM5akx4LXNzME9HcGJBUi1yT19OVk5wb05BY25NLXdaMF9LZjROWHpwZENrNzRLSGQtV2hzTGNwa0V0ZjJHUENEUE9kSG5QRWZEQjlvRjd5bTZsb2lWbnpxTHN5LUVOdElLamFReHRpZk9CYThUM29DbHg1VGhsbVNIbGJKWW1kQno4LTlPb1MwMV9xWkd0VGNfeEhSRWxOWW0wSmZTbWtRZG1JSG5WT0NsSTZabVF6dERLR25kSXRpODU0YmlEQW9FRnZrMnp6LXdKSUtJdk9VQURwcVBWRTZKdGRWV0NDQVZjaE5rQXBrN0VtT2RfaWdZdm5MQlFPZl9xYm85eURHc3pxbjNzTFhYeHp6cEUzTWRreXZCZjFyeC12U25GYlZGaWl1dzNnX3otTzE2V3VHRUlUZFlsWDNWbkhHZi1RVHpJU0tWbHM3UlJwaFRFNUFDMDBQVVVCNU11WF8yRmZNMnJvTU5EczR5amdsOWs5UWsxU2lUcVZaWmZQTFNaRkM3VEtXZTlnVUtLWkRCeW9KV0ZBRDR5VWtHaTVTd01RX3VySk05dkJGXzV1YlFRbTM5UU42ek52WUdqZUgyUXFIbmhNbGlwam93RmxpdnU4b0NHSlp4MGp5WllYb2RGbE91MllfdDJIYWVMSU1PdFhpenhNN0tmTEs5UWgteHRfYUhxTnVrTXFRS0xzdzRKb1pHSWRXYXgzVjdVWXdpRm53c01CRzI2NHZhaXQ0NzVWeVFqV3FFaUdGVXRjN1I4VGNzOTRiTm15WS1IVEhtNEFjdUQ0bzNETzJXU3RxOE1rMk1FZEZrd1hwNlRWV2lQdFZOR2NkTUJmcjdlODl4ZXE1MjQ0VVBIWGtfWF9ab081QnpDUEY4VjlDdHVidnBJaXdOZWJMUE4zOG1JY3ItbF9wWmpGS0NrVGNEeVF0aG0wY2FjNnNEbE1vNUNZTU4wd2FLcUgxVW5fS2ZuZ1Z5QUFBZFppOVdnVTdycUFiaXZQQW5adS1qdHU2M29mTDcyS05jemNLcUxtNUlVZ3RQejhxSldGdWtkYnQtV3dBSGZQWVFtRGJueE9pUHE3akNRZlpZTGN2WHhvZDJPN1RSa1A1VEFBYUM2cEllN0hHdmVOWnJtLXdJSk9CR1I0X1ZCY2JyMjNJQk1MSFlXVHQ0LS1NYVNzV2kzalhvUmRfcVM0VGRyRjF0bW9LaXFLUDVTeF9rZUlSWlY3WE0ySkw3d3ZKdld5NkxTM3BFaTc0bVlsbXdHc1QteDN3aGtEeXFnMW5RM0hVMW1qWUVLODU2UFJnV1VUdWxjS0lPbDk4REdpY0lXNkwwRGpISFlIb25teWNXcHNieUNPX1hjUUVYa2VEUW9Tb2dXckItNmE4MjF2OXFnajBkWlZkMnBNRXJRck1aREl3UUVDQjhhejJOMjgyRmZuNWQ1dzNyTVJRUFRvdWo3RXU3bHpQRG1NMFZfNXFiZzUtMVJ3ejJKOEFRQmRoUVA1cXRJMlp2YlZLQlZSOV82THNtRGJWR0hUbUg3OWpxS2RkcVhfeFZUSl9ERDQ0a1NkUHJXZmtKVDRvQkJxQnlRWTF2OUxRbU95YlVIYkJCcFpoTl8xMWJDYW1zNjA3ZEM1WjhVcUZGX3AwRjB5UW9EQlQxTkdvOUkyMS1FenVsYmpTZGttT1VGb0luU2dtSEN5UndSdkx4SkIwdjQ2bUhPWVFWdXBCY2ZtbXlBekNaa0kwQVpsRVVIZ3MzZU13Z3pIRFFHMXpsaWVmX0Jma1VMUTk3NGg5RExNdHpIelJLYWc3X0ljTjMtZXNqMGI5NHF6dzBXalBQSG40MnVwYy1EaW0xWTRtN1dkZ3M4aWptTDhlZ1JoWHJmNzhLNHJjUWN0bWotRGpNNnJnZWxFemlveTRNU0M0Z0xmT0Z1VjBaQUh6aVZ0SHIzWEJkZkN3MGw2YkRhQlViUjlZZ0k5eGN1dWdNT2d2R0FqanhuZnFfSi1GVDF1UzZQeE1pNHJ0b3V0S2p5TEFCSllUZDhjQlU0Uk82dGJmUjd6RmlRS2tGenNnQkFNNkJVQzc1SWh6bl9VZlhJOVh2dHRuS3FKcHp1Wm0wZk42bG5rZS1vLVZIaTJUN1RwOEFhLXA3	192.168.1.8	615278825245754252378015020576386927611302184471	2025-11-03 23:01:39.925373+00	2026-11-03 23:01:39.925373+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 23:01:39.943474+00	2025-11-03 23:02:29.386329+00	f
a69c7132-2656-4d4b-adf5-e8c273a0c72a	Z0FBQUFBQnBDYVVGd1ZMdXZaSVh3dWc5QkQ4b3ZKaGRuZWJEblhuenBJanc5Q1lUQUtTUEVwWEszQTZNcE83LTdoYjFON0FlbE1YS1hRMFAwT2x1M0VHNkJueURrNXU2YjlyRGtUR21qdk9kSmdFRW15OXNaV3ZYY2V6clFvdzJOTm5xaTBZeTBkR3VidlNWNWtlQjc3OTBVZkpxV1VKWVRrUnl3V3JvdHV3ZzVITHNBdTlDWktvb2txZC1IMWoyUnEzMnR0bVB1WkFzZzktY1lxMTNFemx0SUhlR0twWnVybEllTEZfbHMyWGN1TFRhUVA3bjBqbjNaYmJ1N3pZMmhxZ09LZGhmaloyTmN5Zk5QUmtvemd2aXZiNlUyYTdPekJ1dkdOZU1Nb05seDhnVTZiSUxSdVQ5d0JpTkZyMVZ6RV9oU0ltYm5FdTFPTWtranJ5TGZoSFY5Z3BOd2ZmRGVqd0tsWDdkQlhWTmh1RzkzVGJCc01ob0ViUnBxUkFhcTc0bGlNUFJhSDFuc0FtNThVSWlyNTFTX2tmT1RpMHFVenpuQTRVRHVWcFEzams4Q3ZZUzdOVjlSanVSbVNWN0NnUG9HNk1oMlNWSFlHM0JOSWtqZlFsQ1BuTmFPaUtvNW5JQ3FreUt2c1FUZ21yR0FEbUl5Vk8zU1ZKLWtXeEJGUTF1VVZMRFVUTU1SbHFRTW1iMEVRamJpMUpUblhUMXZaYzJiRUU0SVB4bzBvelFXTjBTU293WFdlRnZGeHdfaXpyNGRhdWRzODhFYlc4allSQlBpT293S3FHRUFQN2xmckQyaHZmWExYb1NhVHBJWjR3M3l5WmJzYkc5czRtXzZSWUJKaU9uUmkwYlpqMnpRVzJhODM2a3NPZGJFS1pSVGphcGZMcVAybWd2a0dtLTVwTXN4ZnNWaHBPbmNTdVdPeDZwZVpMeG5NcndKbmloXy0yRFhJb0wwZkRxODV4VWR1OVhLT0ZiRm1DOE12VWJnRVhQVWwwSk1fVFQyTjRQOVZZVlROZE13eG1DTG5oaXRNc1hfOXNXd0NRRjA5N2FGcXprT3lKSHI1dHVyUVVKN2NlanVjeEw2Wlh2TGhPOFlWNlhkaGNtYl83TWVvbDRtMi1mN1Y3cXRmTng3WnNxSFBkNnNWMGpnWGlXXzFBdDItbE9DT1ZfZzVDcG0takFuVlk5M1ZiUjV4OHJVVW5ZWkM1dHlRUjJpUFB6akdLSGw5Y053bkFCWkhrOEpJOHdlWkhKa2NuYkdma3pScFlCdmVQci1MZ0FaNUZUaWdTZzkyaGVhUW1DWFB6THZnbzZESjF6U1VrTGo0czRTTVVvc09zZllpQ2phTHdUdmdNLWRiWkx1OUZwWG10dkRMdDVjQVBVTnlEUTR6SE9xTXBDQVNMSTB1RHhIVGl5MGRDVUxYNlUydzVNaTc4U3VrWnFmVm8tQVAzZHNwU2toeU5yTU9PWFd1VU9wbkpSaDBXZGJQMVBFZnJWZkEwYmNFazA3bEdISXUwUkplN0lGTU52UHNkNzBvb0wwdVV4YXQzZHFDbWFlT0JyQk8xZGJlTVV2ZkZVOXBqMFVsOEJZNWFia0pEZ3MxTXpnUHJnRmNtaEpxUmhFRVR5Y0tSNDdwMHVxMmZSeWFNZWs5bXg0UVMzTnI4dHNHNFMzSnk3ejRGbXExYTAtekpzSG1XS0duSFBQU0U4T3FKTDVFa2xtTFFlQTNaM1JEYVRaclN6ZE9xT2ZlLTNKT1Q1QThpemJvZFVpd2RjaVNFVUpQZnV5Z1RvX2ExVTVrTmJkX3Qyc28zWk85aFkwbEhyOVVSOHd4cTBPaUZXejZXcUloMDl0ZzRvSGVmUkRqMVVIb3VwaHQ2SGVjUTFoVjVtZVZWSFJYMkhyTUk5Yk4xMm1EeU1CUVVXX1MxanRrTUR5Ry1vd2R6czBwYl9Fa1dRWU1oWVNYY1EyZVVnTDc1QkhZb1o2YXAwcFp4b2w5d3ZVR0ljWVdYdXJMQ25DVVNseDM1aEhTV1ZxUmxtUDV4UUp2bVQwSWUzX1lTNi01V3Z1cVhsUEUtSXBFbnRhREJTcl9CSEdyRWkxUmEyM0ZBeFhDMkpBbm9DOEdoNzFoRHM0SG03N2xkM0gwZTFWMmF4STlIYTJLU0x6YUFsV2VBYzJyRkFrNDgzdkgydURJaVFNanI4WWhIWV91dDEtNDFjOVljSEhVYWtCckdPZnhTY3Q2bmwtNHAyUTFia210ejlTSkFuMkNfM1paOFN6eW4wTmpTb2MxdGhHTUc3QWF5SXZEc0cwS3ZmdTE0XzJyMnAxQS1rNTV0bHQ2VXUwOFRhaE5ac2ttaC1Nekd3UExhY1ZENW81UU5PcW56ZXNGalhDR2dpSFpCU2hTSk4xTUR0UHJiTFdlajMyMTBnbkw3ZVVpdTVmV3BMQkNfZlFZMmdCYlNWdFVYdkFxTjB2SzBBYTBkVzZQdkhxTDFiXzNLcW1nZ05yX3BtZ29GT3BvdWZWR0VqX0hhdDRXVl9kckJBMW9QeGpSaHNNdmNhckpvPQ==	Z0FBQUFBQnBDYVVGVkJnYlhBbFFqQjBLdlhXdVc4U01UMWQ3ZWcyMzNHRmVVcFFFSmNRX2FhTXZnX2I1Tm5LV1QtdmkyaGFQdU1EeEpfeFhMSU1zN1BlR0h3Rjd1NG5jRU1TUFNfM0tYeE9EVWRiX3RyR3FPc05xMmpLVUFya29qNFZJUXl0V0Rna3hqUmwwRGlwNUNMWlpZT2pXMnV6R1VrMUFwTXdYcDFIM1BIRFhEUUx2cEo2Tjh2dzZFckU1V3BtbXk5MEZqTVdXSnRKQm5xa0ViTFFIMTFSMi15UW9EOVlYeVBtZUh0Z1BYQVl5S0J5anpwQm1sMHVwQ29TTFZnUEJ6SDVJc3o1aElGSXVmczdKRkR6TkdGc0lYMnFXME9WUFlZa1pTQUhldWZxcXplZHRrXzJHS3lXdDk5STI1UzVBQU5sLVAtZGFsR0pnNlM4ZUZscktGUjJHZE9TbHE4QzBLRFBsRnJkenNwTUJYUWJZWlFrM3B0UTdzNGduejMzQjRwbVBlcEl4UVdVbkV1WjJpQ0xuWlJqN2R3dDVLbUNWc1U0d255eGQwRnZJYjk2WFh6VWEyMDlVSDQ1WFh2T0x5UWZWRWt4cmNFbWV6SDRBMkdVeTRNT0NvWVROcmpncWJJaWhyazJVVEFMUENsdWRIbTdWVENjWHhvcG5ZZzRSZHNFZ2RmQlltNE8wdVdsd3BLMTlEV0Fsc1NMVlJoSTRwbjNGblFWWmZBT3F5b19sZEFvS25WZXhNWUpDLWxuVlVfOEZLLXJlQmprbENxWnBKbUJLZGhCM2s5X2p4UFAtcVI5SDlPeUpaM1pqRGk1REoxZGtHTnN5WlExS2FZNmF4cDJOVFhqM2lZNkdHWjlmUldTc0pCUnh5NE5yYnBTWFgyWE5UWTRuQk9LeUQ1dkJnUmJ0bnNGTzFPajdhc3ZMZDdfSmkzUkhyMS1DVHNESFB3cUJCQXpQWDhQRUNUMVN0VHhxY3o0QzNWWUpZQW1VSElWMm1xaWJnN3Z2bzdtNlBJQXJadzkyTUtuZFRESEFaWjMwV052STI1amxjT0swMER1QXBwbXJ5VHIzX2dTU1pmZGVrakpyLTg2dVJMZWVpTW5MdldUVE9KTF96SFN6LWVNa2J4TUxjcTFxWlRrWnBnVmVUYlZiaHlkeF9mTndDajVGQ2J0bTlmVGF5cmxCMFVCUGhJTXlUZ2hHcjBRWm05V3VCdjcwYjFMQ0kzZ29tNnZTRHJnQjZzVUhPWmRGaWEzZ3NURC1fd09BYjAwcXBHc3N2WU1oS2FGVVBzZElmV2tGRFNnX2NwOVYxYy0zQkR2cnJlamVSQ20xc1hmRFB6UFA3ODZJMXVXVkx6VkFpa1k4aU1oS3RMVDBtMWJuZFp0WDY2azJwbFZDbUtZRWNYR3NTbmlyem5qQ1V5YVBRbE1LYUcxZVI5WFFjbnJEcVJaaXRIOW5idzlwTFgtc2YzQWIxLXVWVzJDNHhVbXZBUDBpOVZjc1NOOHc2RldzNVV3NzFjdV9CV281aWxGMU9ZYkRsRTdkT0hHQVBwQ0JwRHYzcVluMnpwOW9mNm5YWHhZcnZkUWtMeDFBbFRqQTh5ZHk5akJlc1ZUNy1GQ2NoVDFkdGVnVUZLT09HOXZwWThQWTFvTVJJU2VWMlN5WjV5VF9IVFk0V2hmZldpVG9BX2N0cW11MEZvNnp2VVV0dXM0QXlvbzBLaHJHMlpwQkYyYkpYTlBRRXZqczJzcll3VUwyZnNNN053QWZuSGhRZlNBSjhNa2xhekFMTVFsMVJXVDh6ZTdLbmdSMUZ4VWNUMVhNcEJCZ3V1RlRfWW0tX2ptUUI3SnBDdmRxQ2JFVldoTXRfU2pOTDd3TDlrNXAtUFhKbmVOWU9tdWh2TDFyRXZsNTVHSy1IUGZKa01RQm1xaVFlb3F0emRPRVhjNWtKQUpLdHdSSk5CQnpkTFRndlo5Y3NVQ3luMUlvQlU0STdLNG5kYXJ3SC01TzBnZkRkdGFvVERwZjNIQi1CRGpfZFlwY2R2VXYwNVg3QmF2NVZ5eWEwOFktUkxBZ1RIdm1WQVNUemlTbEVYZ0NXMF9qN2FSOUVuZ1ZraEhlaWF4MFNELWJqQ0tHbmQ3di1MTmdCSkdQX2YxWmlVbklwRjBvR250M1FLbW9XWTlfdGJfYnMxV1p2VGRnOGxsaU1LRmNUZWVORkprM1ZqdzdSUlBFUDdrVzBVcUpwemFrNXNSem9MRUM3YTNMUURsVlV2bmFTcEdWdmE5TlNTREh5VGN6SjNFMG1zRnBqa1JVbERjYjhFemJXcEY0a0kxb1dVZ1FrUE4xQ0RUQmlFZUQ3dGU2amJZdWYtcHBDZGNGX05hSHhGQlU1NWVfNXV2bmhrUkZqTm84QjhaTXhpZ3JqUk5oejFNSjh2cVVzWElFOERZb3BJaDRyaHdQRmlxOWVwZUFmSkdlWjNjbDgtN3c4bDlNaFZUazlodnhibEk5am1ia09DNFV4RGszTzB4QWRtZHVuTG5qcVlmTW9qdnUtNGFBNHBTVF9ENHdKWV9GYlFDNmpzeXE2T0d2anpUWGp4T1ZoWlRWSUhqZGxzeWt3SkpRVW0tMDJ2NVFYVHlfRWlldnNrMkdoMVRraXU0cExQM0E3R2pVVjkyV0dmNFhtU3ZRTDdJWVIwU2huZURBb2VpWTZyLUI1Q0JGX3duRXVLYk5UQVVFX2VQTmxudzdHN04zNm90ejNIT1oyOXNrVl84N0FuRVBlLVQtcmxfS2NKbjVDMmtyMTh2SGVWa1U5d1RuejB3bms3ZncxeS1sai1yUUdkem5nd1lZTkVvM0Vhc2JjRDlIN0NuSmczenZtbHB2cmNFZEplejNIS05BdldwdzBnbWhvSTRIR1o5QkNVZ1hYMGRVSFFXUG10al9aYVhGdVBjNUZiSVlqbnJLTmkyM2lGYTBIaE9jNFJBY0VBR293dmQxQVR5WndibVBUNW9neHVXeDFqRE5tTjJkRnQ4MXBXUndvRE13ak4xUnpWdWwxaEQ2LUpfRG8tbEZILWVNcU9jRVpkTVdQVXZVXzFEaU1ZeDVidlZL	192.168.1.8	80020372516725120716209956992906520873074118592	2025-11-03 23:02:29.39947+00	2026-11-03 23:02:29.39947+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-03 23:02:29.401658+00	2025-11-04 03:35:52.910368+00	f
222f09a9-91ef-4a45-8603-09fef59f25e3	Z0FBQUFBQnBDZVVZSnhMYjF2blNhMWdkTUNqaDJkc1doY2tVZXl1RGZYNjJodXplSG9WZ1p2ZHRjVkxzOGEyWFc2SEVxWFY5OGVUN25GRVVhZlYwcWY1OFY2VjI5N0pPVkM2c0ZOVE43VEZPS0cyLTZxTEpkTEhMdjYzcndxQmV3YXRpdGxvSEJPU1QzNE1RRXhQMjlVSkh6Q1ByZG8zN2p1Y09xbWt3ZGdPZlFTc0E0SUFTSGJQMHpPNUo1X1dxckFuSUg3OXg1b2ZGMFpvUFNhYm0tbjQ0TEFLUWxrWXlmVGxCVWZkRk9USVJ0ZGdvS0IwbFhjOEpPU1k1b1k0LU5tRHVVeW5wM1VqM0VNb1IzY3ZOWXFSV0tMSVB6eHZXYlhseDFKdllYTkZKOWpNbDFaU1hYWWVjMWVLenhYRnpHOW5ET1ZRc0V1SkNDV0N2OGpHYkRsQ0FidjRocWRpcjFvVFA1REM1blY4M18xblJJRG0waU9YVnFfblNHcmFUSWdXOURxS3lnSkppdE5jdFMySVc2UWR2Z0RVRVpBeVNWVFV4THpQOVhpVDJFWXdWeGJaZHVuM0xQQTlPWmdmRlNwdlpIeXVuYnlfaTZYUHRNS1dGSF90QUU4cTFsajJFY1hkRlQzSHBRY3gwMEpkTVBSa21SaEVXTGx4RGdhb1d3THlfNmwyTnlZbkVhWE9oVzc1OWlFLWNsVHFtNEdWRlA4QjZDa1RxbjhSY1oxVjd1Rnlrc1pmRE9FVzVsc0phZlRwVnBFY2FySThzR0RtVUktdjVrVGlSVWpXa3pxYjhCdjhEYW9aclNzc0ZyanA4aERtdVNmSlhRZENFaW9mdVVpTVdpMU9BdlQ0S3JJb0dCNGZLT1lqU3I0WVFhMHFXVktqOUtxT05zT0NrZlNDdGNJNThucWJVVXpoNEtub1FWYnhnWUN1ZFdncmltNXB5YndWU05vd0xIRkFqcDRWUTgzWUZuRjBOQy1ucG82SFFxbkJsWHpxRHdUdm9lQ1k2NW50WlIyYThMel82R2VCdXRjeFRZQlpvSnVVN1liWF9PQTZHSzBfQmVuTkxHQVZNbG5OT1VPX3JPTm9aZFFzOVNpSWlmUzBnYk1oNnE1UWFpZUJfcDltZHJhendUQlZ3SmRjU2FUaHlVVW5HdFN4T01aT1VXNlp4ZzJGT1NZb2RZNGVqWDZ0SHo3d21ZVDF3cElrOE5Mc0tXMFdvRzNPX1FMY05laVgyemlLbEo1NXJxenFCY2FNMF9wNlJzQlJPdEhTaFY2ODRHbmhlVGhfS1F3Q19penFDYkJrZ3o2V2lWRDlzSlZIOUdaSEFOZXVSN1NYT3pSQWJ4cnZqZFZJbUc0N0hjQlZtcVJBQVRXYzN0dGVfVjA1UDktd2JGWWZqUlNzb2lMOF9fZU5JanpfN0M2eG1PbkdlQ2F6WHFaUF9XSlNma2x1Zk50NE9qcWFHckUtaVBsRE1ta1VNMXYwMlJQLVZYcUpUMHNJVThkWDVQS3hlNVhBdkNnZHJwb253cXZ0aW5tVlRrUWtVbFlHMEpOU2pydUhVM1lnX3A1czM0WjBPRlM0a2ZOYjJMLVFFVXR4VUdkTFFrV0lGSlZhbl9vZmNxQ1lzcllXN2ZjdFp3TFZER3FxODVWMGM2MlliSkxqNzBOUGo1UVNHdlRZS1p0YlhadDQxekl3Sk5qLVdGMzNYem5pV2NaS0ZyTUNtS3cwbTlKbk4taHFDdHkwcWVOQk8tel9vcHBZdHNsaXkwdkdnRVAzamtFUDBwT2pyQVg5NE5WUTVETzA2VkFsTWJac1MxMHpVdWhTVkcyWGQxaVdHWWF4elpSME55MHktZzFhUWJqVFdXamU2djVTcVVyNjNQVll0eFZKM3E2LU0yYVNUaEpQMEVQU3p4RXhkaF9fSUt2S0NXRmtEaW1uZ0M1VVBpT1JUMTZ2TjdmNmZaZGhDa2RyeHFncHVqV3FwbzZob2hZVGtzR1dNLUd5b2xHdmVVaUNEa19RQ0FrVDY3VDNMeWJqTUEtRHRSMzlVejhHQm83NkgxVkZzZzM3eGl1MnpiNGxOeDVpbW1rNFVoXy1WTXZwcGZJVUZkamdRUVc3dDF5NzQ4R01vUUpnV0tYb3g3bjkwd3l2VFJTLUtpemxHMWxHMFB3ODVpVXAwWDJMdzhjRUJYTEhOeDFPVlpUYTF3bUtONlNLc1V1OFpSUzhYMzF2NUtlcDdXRzd4Qi1fNDNBNDlfTEpyd2JBT2w4ZnBpZXFkODJEellEcVZZdUk5VnA0TnZpR2M0RFh1UXcwcjU5MnJMZTRZQjU1R3FTQlBDd2ZlbGJqbmllODVwR3RBLURnWmlKeDJqY1JxbjJnQmRES3lOSmIyVXRDMW41aG94dVMzbnRSZnlIUm1RT2NVbTVNLTBJQVdtNmJsSmRKdUxZNXlHODRYUEdnUm5Hd1lWNUJkcFdUd24xdGh5M19WTW45S081LXRHRGVuZlJoclluZHN5ZlZJQThEaXJRPT0=	Z0FBQUFBQnBDZVVZdHRjTWdwdmNCVTFFa2lKSWkxY0VhY19vdFluX0J2dnlDUUlsemVSOFNfNVBXaEtSY085MHYyTlNUS1hqVGNfODZQWThza3NFSnU3VGpUWm1KVzZLcTBqSmlZWE8xSXNSR21MZjRwajdwcHVsN2REcm16ajhwd19WdmhJakhUNldncUU0NDZqZkJfdlF0bi1GUXdVV3EyT3gxT0U2NkJDNGQ5eHhlbEhYODJZMTRoWlcwZXdWanNORkExWHhCYlFpNzdQYzUyazlOZVBYUVI3bncyNU9zNC1MNXhZVjZWWnV1NnRkZGpEZVU3Si02QXFwRTM4OW0wR1FGRWJLRktjYWJRMndDbklQYjFod3QxdF92UzBYT29XZDVNcUs5QVRjTng2NUNiNE5FMjhQa1dCbDlwRmtqYkFITEI4aWJDazBLWEo5Qk9UWkhZc3VGaTRETENsRUxZNmZFcDlWWGVwUWxVU0dncHFYanZoTWpZNmdtNHZkYzNDQWxOOVQ2cnBXRllVOXlrYkV1Mm5nT2dPUnZ0dkY2bGZtckh1RU1zbGNPU2RWVGZyb0dMNXJZMTBUMGRBSWpqeXYtOUF4X2pYVV9Wb0dMVTViVWJORjRONUtjZDczRW5zQmhGc2Z5dXNUa3J4ZkVWUjdwdDdjcHh2T3U3T19WRlRpN2FDZkl4VWZaUUlzTHl0bl90azh3eXM3YzRwLTBxVzRuSG1LZGJFXy1DdVFvUFItNVhFLTJTYzd2VGxxOFVxTmx3ZXRDMURhZ3dYMjdaTTNlcmNQRVlPUHk3NHBUSEVLRmNzQVNkMjdFeE9sV1F3dWdFcy1FUzA4T2NCS1RZT21uZTNpR21XN1cwVHJGcjR0MjJQQ1RlcEh0M0xIRTRERFBKZy1MbzZyVnFvWjE3cHVUUE9TZzA0Q1hoZnU0ejZvZzdaSHFfaWU3bHpvakZoa2U5U2J3OG1ETjBmamlKMG5vclM1SGh0cWJoVi0yQmZsRjI5SmoyQll2U3JBNllDQnN5akw3NkdFMkJCX2hpdjQ5RG1zWXJxTUQ3T05wY3IzMERITTRVcHJJaVJ1Nng5LU12ZmJSaDB5Yl90ZEhYQ0FsR3RweE5KeVp6TmJYc3lMTW9SeDB0TGRDR2thZjFTUTl3Q1VrSFByMU1iVWdfb3I1S0ZaTnRSdFpnbmVOendGY05HMHFQRDZBSmh1YW0tUWt2MWl0Sm9NaXdrOW0tN1dwNUFxMF9panNZNzZFcU1zQXVWaGdUbG9hbXFqdHpLSXRpUVIzZlVwTzhNRERoczB4SThWS3Z6TWN0VG5yU0Q4MmhONW5fRUlaTWYzcTd2Z1hkR19za3ZMbTBCU3JLWmlnNnpBUXZxN2tCUzc2SVF2Um5vTTFsa3d3MXlXeU4wLWdaaWJJdl9VMG1jRXJTelVUUEc4WnVyNzBjQTZnTEstVkp2UXBWdnVDUzlVa3V3enRWYmtnRnJ5VjBQX18yMl9GcGtUanJXRGJhRmNzbkJsVkotZklmUjRockFJQjdIckhxQldWbllqWlE0MmhzVjZqNzROam1ZLURBZnpyQXBJVnVlRUM4LUpCaU05aVZoTkE4a0lib2QwREtYLUcwSmwyS0pUemExMVdwbEZyRWtYdnBURHhsUENSYlhHbTFjaWtNZzhWTnBURU5lbDdJbExwMFo4dTJXMmNieENDb3BfVUozVi1DU29WbFlwTGl0YWllTEdJV1NhQmRIczRqdy1yVjZLSlZ6WHlwMlZJS2FXQ0xrblJ5U0U2UEl0OWpMQ25IamRLVlpXd2g0dWxqLWZWcndPdkZBR09KNHdYblZBdUo4emVha1NMUTFQU2tyalBLdkxpOTc4WXVXNEJ3UEVacl9pQkZsOVVqRHFqb0ljUFFUOHRNNllCVmsxem9PNmhJM1pzWkFPeVJwa1UxWVczRE9NazRoQUxOMkkzajFhQWVQV1BDNUx5NG9fZzNjSXpFanJhZ3JscTBNQm53QmZLQ1FvX0VMalBLZ2VfZ2h2clBFSThXQ3lEYTJ2bzdxMXlNTjVVVVB5SXVoR05VaV9VaXAxS2t5bnkxZ3REcW8weHpSRjctR3JleGRYaXhKSFJaVmhPa1ZKNW0wRVRyT1M5TjZzbUlkOS1GNzZSMWlGUmRxakNoR1NOb1ExWXpQcGRUeFF4YWJQVk43dDB4RlZGbHlNaGNWRXdySktTeFhVMU53YzlQX3hpdTFnSjZoUW5hY3ktdVFpa2kwZ0NJWEpnU2VUX0VnalVWOFdjeTFXWkt6ZE1NZ1dMbk9KYl9HYXVnSUt5cVgzTXUtdUpkUGlaYktjaUV1Rm1nUGE0ajBHaEN0VUI0TXZGd191bFZtNFp0bldKbENoYXZ6OVVIR3lHSGhDeDRjMjdqajVfcnh2cWNmS0JranAxaG9QdE9xNHdua3FWalE4d0lGRDRELUlFNHBSbDJweE9RSExQcG40cy1HZ3A3NlMyTnVKeU1zQ1RpUGZRUEdEcHRkRTBtMnlWU012NXVCQmVCRGVFc1YtZXZFa0JnWmFQMDJIUERqY3dvbTRsaVhvNUhpYU50S1FlU3dKRUYxUEZVZUtNczN5bnB5SlpNWDVXaGNJczVRNjg5QnBnZlNKVFpiczFmMmstSnZCLUkwd0llZUpHckZfUkVGb2dieDh1MmhKaXhsOG1LRFVDQnA1R2FjTkFoVFkxbXk3NERJajdoY09QRW9OOHByTXdxd0JKLXdUVS1hNFdLR0hvSlRFOVVwZ0xuU2pkX28xWU1fWW04OFVaZE9ycWNUNmNXRExaLVIwMUxaN2RHaXdwYnYzQlhlX2JUeWgwV0xQU3VOR21GcVdmQWVBdHFYbWF1UEozWEZ4MUdscDJ1aUxrZHRpRmNJdHFEUDhheDV6RU56MUJ5a0M4dndfUDZoSkszYklDOHdXQUFoQTZpd0dDYnhzVnRmbTNXanZBcmVGVGc5ZzByQWR1enlBaUd0U0EtQV81eUplb1YxcGdTRlJnSmZLOXlQc0s4TmZvaTQ5Y0VnVExibDg0ZFEyZEg2RVB1cVpYOW5FdTZncEJjUWtHLTRi	mosquitto-broker	268480445756863101034152596184765639202205837214	2025-11-04 03:35:52.916278+00	2026-11-04 03:35:52.916278+00	\N	\N	45bbb358-759b-458b-a04c-a3d34b8ad09c	2025-11-04 03:35:52.919662+00	2025-11-04 03:35:52.919664+00	t
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (user_id, role_id, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, hashed_password, full_name, mobile, is_active, is_admin, totp_secret, failed_attempts, last_login_at, created_at, updated_at) FROM stdin;
45bbb358-759b-458b-a04c-a3d34b8ad09c	admin	admin@example.com	$2b$12$woDtZc1UC5ESRSS1PjjCl.1zs0Jjyxuis9ZSZrjg0JLNTpFHqO2we	\N	\N	t	t	\N	0	2025-11-07 03:11:22.495894+00	2025-11-03 09:36:44.48464+00	2025-11-06 19:11:22.497389+00
\.


--
-- Name: access_control_policies access_control_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_control_policies
    ADD CONSTRAINT access_control_policies_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: alert_rules alert_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT alert_rules_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: blacklisted_ips blacklisted_ips_ip_address_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklisted_ips
    ADD CONSTRAINT blacklisted_ips_ip_address_key UNIQUE (ip_address);


--
-- Name: blacklisted_ips blacklisted_ips_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.blacklisted_ips
    ADD CONSTRAINT blacklisted_ips_pkey PRIMARY KEY (id);


--
-- Name: device_certificates device_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_certificates
    ADD CONSTRAINT device_certificates_pkey PRIMARY KEY (id);


--
-- Name: device_certificates device_certificates_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_certificates
    ADD CONSTRAINT device_certificates_serial_number_key UNIQUE (serial_number);


--
-- Name: device_data device_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_data
    ADD CONSTRAINT device_data_pkey PRIMARY KEY (id);


--
-- Name: device_encryption_keys device_encryption_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_encryption_keys
    ADD CONSTRAINT device_encryption_keys_pkey PRIMARY KEY (id);


--
-- Name: device_logs device_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_logs
    ADD CONSTRAINT device_logs_pkey PRIMARY KEY (id);


--
-- Name: device_metrics device_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_metrics
    ADD CONSTRAINT device_metrics_pkey PRIMARY KEY (id);


--
-- Name: device_templates device_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_templates
    ADD CONSTRAINT device_templates_pkey PRIMARY KEY (id);


--
-- Name: devices devices_device_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_device_id_key UNIQUE (device_id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: firmware_builds firmware_builds_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.firmware_builds
    ADD CONSTRAINT firmware_builds_pkey PRIMARY KEY (id);


--
-- Name: monitoring_alerts monitoring_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_pkey PRIMARY KEY (id);


--
-- Name: ota_update_tasks ota_update_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ota_update_tasks
    ADD CONSTRAINT ota_update_tasks_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: security_audit_logs security_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.security_audit_logs
    ADD CONSTRAINT security_audit_logs_pkey PRIMARY KEY (id);


--
-- Name: security_events security_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_pkey PRIMARY KEY (id);


--
-- Name: server_certificates server_certificates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_certificates
    ADD CONSTRAINT server_certificates_pkey PRIMARY KEY (id);


--
-- Name: server_certificates server_certificates_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_certificates
    ADD CONSTRAINT server_certificates_serial_number_key UNIQUE (serial_number);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: ix_device_encryption_keys_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_device_encryption_keys_device_id ON public.device_encryption_keys USING btree (device_id);


--
-- Name: ix_device_templates_device_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_device_templates_device_type ON public.device_templates USING btree (device_type);


--
-- Name: ix_device_templates_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_device_templates_name ON public.device_templates USING btree (name);


--
-- Name: ix_device_templates_name_version; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_device_templates_name_version ON public.device_templates USING btree (name, version);


--
-- Name: ix_device_templates_version; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_device_templates_version ON public.device_templates USING btree (version);


--
-- Name: ix_firmware_builds_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_firmware_builds_device_id ON public.firmware_builds USING btree (device_id);


--
-- Name: ix_firmware_builds_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_firmware_builds_status ON public.firmware_builds USING btree (status);


--
-- Name: ix_ota_update_tasks_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ota_update_tasks_created_at ON public.ota_update_tasks USING btree (created_at);


--
-- Name: ix_ota_update_tasks_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ota_update_tasks_device_id ON public.ota_update_tasks USING btree (device_id);


--
-- Name: ix_ota_update_tasks_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ota_update_tasks_status ON public.ota_update_tasks USING btree (status);


--
-- Name: ix_server_certificates_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_server_certificates_created_at ON public.server_certificates USING btree (created_at);


--
-- Name: ix_server_certificates_is_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_server_certificates_is_active ON public.server_certificates USING btree (is_active);


--
-- Name: ix_server_certificates_serial_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX ix_server_certificates_serial_number ON public.server_certificates USING btree (serial_number);


--
-- Name: access_control_policies access_control_policies_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_control_policies
    ADD CONSTRAINT access_control_policies_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: alert_rules alert_rules_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_rules
    ADD CONSTRAINT alert_rules_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- Name: alerts alerts_acknowledged_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_acknowledged_by_fkey FOREIGN KEY (acknowledged_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: alerts alerts_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: device_certificates device_certificates_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_certificates
    ADD CONSTRAINT device_certificates_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: device_data device_data_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_data
    ADD CONSTRAINT device_data_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: device_encryption_keys device_encryption_keys_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_encryption_keys
    ADD CONSTRAINT device_encryption_keys_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: device_encryption_keys device_encryption_keys_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_encryption_keys
    ADD CONSTRAINT device_encryption_keys_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: device_logs device_logs_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_logs
    ADD CONSTRAINT device_logs_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: device_metrics device_metrics_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_metrics
    ADD CONSTRAINT device_metrics_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- Name: firmware_builds firmware_builds_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.firmware_builds
    ADD CONSTRAINT firmware_builds_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: firmware_builds firmware_builds_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.firmware_builds
    ADD CONSTRAINT firmware_builds_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: firmware_builds firmware_builds_encryption_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.firmware_builds
    ADD CONSTRAINT firmware_builds_encryption_key_id_fkey FOREIGN KEY (encryption_key_id) REFERENCES public.device_encryption_keys(id) ON DELETE SET NULL;


--
-- Name: monitoring_alerts monitoring_alerts_acknowledged_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_acknowledged_by_fkey FOREIGN KEY (acknowledged_by) REFERENCES public.users(id);


--
-- Name: monitoring_alerts monitoring_alerts_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id);


--
-- Name: monitoring_alerts monitoring_alerts_metrics_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_metrics_id_fkey FOREIGN KEY (metrics_id) REFERENCES public.device_metrics(id);


--
-- Name: monitoring_alerts monitoring_alerts_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: monitoring_alerts monitoring_alerts_rule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monitoring_alerts
    ADD CONSTRAINT monitoring_alerts_rule_id_fkey FOREIGN KEY (rule_id) REFERENCES public.alert_rules(id);


--
-- Name: ota_update_tasks ota_update_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ota_update_tasks
    ADD CONSTRAINT ota_update_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ota_update_tasks ota_update_tasks_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ota_update_tasks
    ADD CONSTRAINT ota_update_tasks_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: ota_update_tasks ota_update_tasks_firmware_build_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ota_update_tasks
    ADD CONSTRAINT ota_update_tasks_firmware_build_id_fkey FOREIGN KEY (firmware_build_id) REFERENCES public.firmware_builds(id) ON DELETE SET NULL;


--
-- Name: security_events security_events_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE SET NULL;


--
-- Name: security_events security_events_handler_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.security_events
    ADD CONSTRAINT security_events_handler_id_fkey FOREIGN KEY (handler_id) REFERENCES public.users(id);


--
-- Name: server_certificates server_certificates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.server_certificates
    ADD CONSTRAINT server_certificates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

