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

- [x] `Outbound.Direct`: preparazione sessioni, target e payload DM/self-chat.
- [x] `Outbound.Group`: sender-key, partecipanti e distribuzione gruppi.
- [x] `Outbound.DeviceDiscovery`: risoluzione USync e cache device.
- [x] `Outbound.Prekeys`: selezione bundle, bootstrap sessioni e fallback
  batch/individuale.
- [x] `Outbound.IQRequests`: boundary di effetto per invio, receive e timeout
  delle richieste USync, prekey e group-info.
- [x] `Outbound.Encryptor`: cifratura Signal per-device, alias PN/LID,
  diagnostica prekey, copertura fanout e invalidazione sessioni di retry.
- [x] `Outbound.Fanout`: risoluzione target e verifica copertura.
- [x] `MessageNode`: composizione finale dei nodi cifrati.
- [x] Ridurre `Session.Worker.Outbound` a coordinamento esplicito di invio,
  persistenza, retry e telemetria.
- [x] Aggiungere test unitari dei boundary IQ e della verifica fanout.
- [ ] Eseguire suite, Credo e Dialyzer fuori da questo ambiente.

`Session.Worker.Outbound` coordina ora moduli focalizzati e conserva soltanto
gli effetti che devono restare visibili nel flusso della sessione.

Criteri:

- nessuna chiamata diretta al transport dai moduli di dominio puri;
- nessuna conoscenza image/audio/contact nei moduli di transport;
- nessun cambiamento dei payload cifrati o degli attributi stanza;
- retry e persistenza restano espliciti nell'orchestratore.

## Fase 3 — Suddividere Inbound per responsabilità

Estrarre in questo ordine:

- [x] `Inbound.Envelope`: risoluzione dell'envelope, identità locali e candidati sender.
- [x] `Inbound.Decryptor`: decrypt Signal/sender-key e aggiornamento sessioni.
- [x] `Inbound.Content`: classificazione del plaintext e decoding dei contenuti.
- [x] `Inbound.Sync`: history, app-state keys e placeholder resend.
- [x] `Inbound.Receipts`: costruzione delivery receipt, retry e resend request.
- [x] `Inbound.Publisher` e `Inbound.Projection`: persistenza chat e pubblicazione eventi.
- [ ] Eseguire suite, Credo e Dialyzer fuori da questo ambiente.

`Message.Handler.Inbound` è ora un orchestratore sottile: conserva il
contratto del router, coordina i risultati normalizzati e delega gli effetti ai
boundary dedicati.

## Fase 4 — Contratto inbound canonico

È stato introdotto `ExWapp.Message.Content`, il contratto interno tipizzato:

- [x] text;
- [x] media con `ExWapp.Media.Ref`;
- [x] location;
- [x] contact/vCard;
- [x] calendar event;
- [x] protocol/sync;
- [x] unsupported con metadati diagnostici.
- [x] adattamento bidirezionale ai campi legacy.
- [x] pubblicazione del valore canonico nel campo `message.content`.
- [ ] Eseguire i test dei formati supportati fuori da questo ambiente.

`Inbound.Content` è l'unico punto che riconosce il plaintext decifrato. Il
publisher espone sia `message.content` sia gli attuali campi `text`,
`media`, `location`, `contact` ed `event`, così la migrazione non rompe
i wrapper esistenti.

Criteri:

- [x] un solo punto riconosce i formati supportati;
- [x] i wrapper non devono analizzare il wire;
- [x] i campi comuni hanno sempre la stessa forma;
- [x] i formati sconosciuti diventano `:unsupported` con diagnostica.

## Fase 5 — Chiarire i transport

Mantenere due concetti espliciti:

- transport di protocollo: socket, frame, Noise e nodi;
- adapter client: API ad alto livello che usa una sessione completa.

Azioni previste:

- [x] documentare il confine tra `ExWapp.Transport` wire-level e
  `ExWapp.Client.Transport` adapter high-level;
- [x] introdurre il nome esplicito `Client.Transport.RawWebSocket`;
- [x] deprecare `Client.Transport.WebSocket` mantenendo il modulo compatibile;
- [x] impedire al percorso raw WebSocket di inviare messaggi high-level senza
  Signal, fanout e sessione;
- [x] mantenere `Client.Transport.Session` come percorso completo di produzione;
- [x] aggiornare README con il percorso raccomandato;
- [ ] eseguire i test transport fuori da questo ambiente.

Il rename pubblico usa un modulo compatibile deprecato; non rimuove ancora il
vecchio nome.

## Fase 6 — Wire e decoder tipizzati

Il precedente modulo misto è stato separato mantenendo la facade compatibile:

- [x] `Wire.Fields`: primitive protobuf/wire generiche;
- [x] `Wire.ContentDecoder`: unwrap dei contenitori WhatsApp e decoder dei
  contenuti supportati;
- [x] `Wire`: envelope XML, candidati cifrati e deleghe compatibili;
- [x] mapping del plaintext verso `ExWapp.Message.Content` nel boundary
  `Inbound.Content`;
- [x] fixture binarie minime per primitive, testo, protocollo e media;
- [ ] eseguire i test wire e dei formati supportati fuori da questo ambiente.

I decoder sono puri, non accedono allo store o al transport e non pubblicano
eventi. Il mapping canonico resta separato dal parsing protobuf.

## Fase 7 — Namespace e struttura file

- [x] verificare che i moduli `ExWapp.Media.*` siano già allineati a
  `lib/ex_wapp/media/*`; nessun rename necessario;
- [x] non introdurre una directory `Domains` parziale;
- [x] mantenere un modulo per file nei boundary modificati ed estrarre
  `Transport.WebSocket.State`;
- [x] aggiornare README e documentazione architetturale;
- [x] mantenere la compatibilità obsoleta solo come delega deprecata;
- [ ] eseguire la validazione completa fuori da questo ambiente.

## Stato dell'implementazione

Le estrazioni architetturali pianificate sono complete:

- outbound separato in pianificazione direct/group, device discovery, prekey,
  fanout, richieste IQ, cifratura e costruzione nodi;
- inbound separato in envelope, decrypt, contenuti, sync, receipt, projection e
  publisher;
- contratto canonico `ExWapp.Message.Content` disponibile ai wrapper;
- transport wire-level distinto dagli adapter client;
- decoder wire generico separato dal decoder dei contenuti supportati;
- namespace e file dei boundary modificati allineati a un modulo per file.

Resta intenzionalmente esterna a questo ambiente soltanto l'esecuzione della
validazione Elixir/Erlang elencata sotto.

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
