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

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recipe_embeddings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipe_embeddings (
    recipe_id bigint NOT NULL,
    embedding public.vector(1536) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id bigint NOT NULL,
    name character varying,
    description character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recipes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recipes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recipes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recipes_id_seq OWNED BY public.recipes.id;


--
-- Name: recommended_caches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recommended_caches (
    rank integer NOT NULL,
    recipe_id bigint NOT NULL,
    recommended_recipe_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: recipes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes ALTER COLUMN id SET DEFAULT nextval('public.recipes_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: recipe_embeddings recipe_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_embeddings
    ADD CONSTRAINT recipe_embeddings_pkey PRIMARY KEY (recipe_id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: recommended_caches recommended_caches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommended_caches
    ADD CONSTRAINT recommended_caches_pkey PRIMARY KEY (recipe_id, rank);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_recipe_embeddings_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recipe_embeddings_on_recipe_id ON public.recipe_embeddings USING btree (recipe_id);


--
-- Name: index_recommended_caches_on_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recommended_caches_on_recipe_id ON public.recommended_caches USING btree (recipe_id);


--
-- Name: index_recommended_caches_on_recommended_recipe_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recommended_caches_on_recommended_recipe_id ON public.recommended_caches USING btree (recommended_recipe_id);


--
-- Name: recipe_embeddings_embedding; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recipe_embeddings_embedding ON public.recipe_embeddings USING hnsw (embedding public.vector_l2_ops) WITH (m='4', ef_construction='10');


--
-- Name: recommended_caches fk_rails_8e742503da; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommended_caches
    ADD CONSTRAINT fk_rails_8e742503da FOREIGN KEY (recommended_recipe_id) REFERENCES public.recipes(id);


--
-- Name: recipe_embeddings fk_rails_8e93973739; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipe_embeddings
    ADD CONSTRAINT fk_rails_8e93973739 FOREIGN KEY (recipe_id) REFERENCES public.recipes(id);


--
-- Name: recommended_caches fk_rails_eab90c743f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommended_caches
    ADD CONSTRAINT fk_rails_eab90c743f FOREIGN KEY (recipe_id) REFERENCES public.recipes(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20231016202038'),
('20231016201402'),
('20231016195607'),
('20231013184849');

