# Piano di refactoring

## Obiettivo

Rendere ExWapp più semplice da estendere e mantenere senza cambiare il
comportamento osservabile, il protocollo sul wire o le API pubbliche già in uso.

La pipeline target è:

```text
API pubblica
  -> dominio messaggi (normalizzazione, encode/decode)
  -> sessione (fanout, Signal, retry, persistenza)
  -> transport (nodi e byte, senza conoscenza dei tipi messaggio)
```

I wrapper devono ricevere contenuti già riconosciuti e normalizzati da ExWapp.
Non devono interpretare protobuf, distinguere manualmente image/audio/document
o ricostruire riferimenti media.

## Regole di lavoro

- Refactoring incrementale: nessuna riscrittura completa.
- Un modulo deve avere un solo motivo principale per cambiare.
- Separare logica pura dagli effetti esterni.
- Conservare le forme di ritorno e le API pubbliche.
- Aggiungere contratti espliciti con `@type` e `@spec`.
- Ogni estrazione deve essere coperta da test di comportamento.
- Evitare modifiche prestazionali senza misurazioni.
- Non spostare logica di protocollo nei wrapper.
- Non far conoscere al transport i tipi di messaggio.
- Ogni fase deve poter essere revisionata e revertita autonomamente.

## Stato iniziale

Punti positivi già presenti:

- `ExWapp.Conn` e `ExWapp.Transport` trattano socket, framing, Noise e nodi.
- I contenuti inbound supportati vengono normalizzati nel core.
- Esistono contract test per testo, image, audio/PTT, document, location,
  contact, event e wrapper effimeri.
- Signal, media, storage e app-state hanno namespace distinti.

Debito principale:

- `ExWapp.Session.Worker.Outbound` concentra orchestrazione, device discovery,
  prekey, fanout, cifratura, gruppi e costruzione dei nodi.
- `ExWapp.Message.Handler.Inbound` concentra decrypt, decoding, sync/history,
  mapping JID, retry receipt e persistenza.
- `ExWapp.Message.Handler.Wire` unisce parsing protobuf generico e decoder dei
  contenuti supportati.
- `ExWapp.Transport` e `ExWapp.Client.Transport` rappresentano livelli
  diversi ma hanno nomi che possono essere confusi.
- `ExWapp.Client.Transport.WebSocket` costruisce messaggi direttamente e può
  aggirare la pipeline completa della sessione.

## Fase 1 — Confine dei nodi outbound

Obiettivo: lasciare al worker l'orchestrazione e spostare la trasformazione pura
dei message node in `ExWapp.Session.MessageNode`.

- [x] Identificare il comportamento già coperto dai contract test.
- [x] Estrarre applicazione di `message_node_type`.
- [x] Estrarre propagazione di `mediatype` sugli `enc`.
- [x] Estrarre append dei nodi metadata aggiuntivi.
- [x] Aggiungere test unitari del nuovo confine.
- [ ] Eseguire la suite completa fuori da questo ambiente.

## Fase 2 — Suddividere Outbound per responsabilità

Estrarre gradualmente moduli interni, senza dividerli per tipo di messaggio:

- [ ] `Outbound.Direct`: orchestrazione DM/self-chat.
- [ ] `Outbound.Group`: sender-key e distribuzione gruppi.
- [ ] `Outbound.DeviceDiscovery`: USync e cache device.
- [ ] `Outbound.Prekeys`: recupero bundle e creazione sessioni.
- [x] `Outbound.Fanout`: risoluzione target e verifica copertura.
- [x] `MessageNode`: composizione finale dei nodi cifrati.

`Session.Worker.Outbound` deve diventare un coordinatore sottile.

Criteri:

- nessuna chiamata diretta al transport dai moduli di dominio puri;
- nessuna conoscenza image/audio/contact nei moduli di transport;
- nessun cambiamento dei payload cifrati o degli attributi stanza;
- retry e persistenza restano espliciti nell'orchestratore.

## Fase 3 — Suddividere Inbound per responsabilità

Estrarre in questo ordine:

1. risoluzione dell'envelope e dei candidati sender;
2. decrypt Signal e aggiornamento sessioni;
3. decoding del contenuto;
4. history/app-state/placeholder sync;
5. costruzione receipt e retry;
6. persistenza e pubblicazione eventi.

`Message.Handler.Inbound` deve coordinare risultati normalizzati, non
contenere tutti i dettagli di ciascuna fase.

## Fase 4 — Contratto inbound canonico

Introdurre un contratto interno tipizzato per i contenuti:

- text;
- media con `ExWapp.Media.Ref`;
- location;
- contact/vCard;
- calendar event;
- protocol/sync;
- unsupported con metadati diagnostici.

Il contratto deve essere convertito nell'attuale mappa pubblica al boundary,
così la migrazione non rompe wrapper esistenti.

Criteri:

- un solo punto riconosce i formati supportati;
- i wrapper non analizzano il wire;
- i campi comuni hanno sempre la stessa forma;
- i formati sconosciuti non vengono persi silenziosamente.

## Fase 5 — Chiarire i transport

Mantenere due concetti espliciti:

- transport di protocollo: socket, frame, Noise e nodi;
- adapter client: API ad alto livello che usa una sessione completa.

Azioni previste:

- documentare il confine tra `ExWapp.Transport` e
  `ExWapp.Client.Transport`;
- valutare un nome non ambiguo per l'adapter client;
- deprecare o riallineare `Client.Transport.WebSocket`;
- impedire al percorso WebSocket diretto di bypassare Signal, fanout e sessione;
- mantenere `Client.Transport.Session` come percorso completo di produzione.

Qualsiasi rename pubblico deve avere una fase di deprecazione separata.

## Fase 6 — Wire e decoder tipizzati

Separare:

- primitive protobuf/wire generiche;
- unwrap dei contenitori WhatsApp;
- decoder dei singoli contenuti;
- mapping verso il contratto inbound canonico.

I decoder devono essere puri e testabili con fixture binarie.

## Fase 7 — Namespace e struttura file

- Allineare path e namespace dei moduli media.
- Evitare directory `Domains` parzialmente adottate.
- Mantenere un modulo per file.
- Aggiornare README e documentazione architetturale.
- Rimuovere compatibilità obsolete soltanto dopo una fase di deprecazione.

## Validazione richiesta per ogni tranche

Da eseguire in un ambiente con Elixir/Erlang installati:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix dialyzer
```

Per i flussi protocollo sensibili verificare inoltre:

- invio testo e media;
- ack server e delivery receipt;
- ricezione/download image, audio e document;
- location, contact ed event;
- self-chat e linked devices;
- gruppi e sender-key;
- reconnect e retry.

## Definizione di completamento

Il refactoring è completo quando:

- transport non dipende dai tipi messaggio;
- wrapper ricevono un contenuto canonico già decodificato;
- i worker coordinano moduli più piccoli e focalizzati;
- non esistono due percorsi produttivi con semantica diversa;
- API pubbliche e wire contract rimangono compatibili;
- suite, Credo e Dialyzer passano senza nuovi skip.
