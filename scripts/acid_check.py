"""Demo interna contra MySQL: usa el servicio real e inyecta fallo tras flush."""
from uuid import uuid4
from sqlalchemy import event
from app.database import SessionLocal
from app.models import Compra, Copia, Juego, Persona
from app.services.compras import crear_compra


class FalloControlado(RuntimeError):
    pass


def main():
    email = f"acid-{uuid4().hex}@demo.local"
    with SessionLocal() as setup:
        setup.add(Persona(EmailPersona=email, NombrePersona="Demo", ApellidoPersona="ACID"))
        games = [Juego(NombreJuego="ACID exito"), Juego(NombreJuego="ACID fallo")]
        setup.add_all(games)
        setup.commit()
        ids = [game.IdJuego for game in games]
    try:
        with SessionLocal() as db:
            crear_compra(db, email, ids[0], 100, "normal")
        with SessionLocal() as observer:
            assert observer.get(Compra, (email, ids[0])) is not None
            assert observer.get(Copia, (ids[0], email)) is not None
        print("Caso A: Compra y Copia persistidas (lectura en otra sesion).")
        flushed = []

        def fail_after_flush(session, context):
            # Las dos escrituras ya alcanzaron MySQL, pero no el commit.
            assert session.get(Compra, (email, ids[1])) is not None
            assert session.get(Copia, (ids[1], email)) is not None
            flushed.append(True)
            raise FalloControlado("Fallo deliberado despues de INSERT y antes de COMMIT")

        with SessionLocal() as db:
            event.listen(db, "after_flush_postexec", fail_after_flush)
            try:
                crear_compra(db, email, ids[1], 100, "normal")
            except FalloControlado:
                assert not db.in_transaction(), "Falta rollback explicito"
            else:
                raise AssertionError("No se produjo el fallo controlado")
            finally:
                event.remove(db, "after_flush_postexec", fail_after_flush)
        assert flushed
        with SessionLocal() as observer:
            assert observer.get(Compra, (email, ids[1])) is None
            assert observer.get(Copia, (ids[1], email)) is None
        print("Caso B: Compra NO persistida; Copia NO persistida. Rollback verificado.")
    finally:
        with SessionLocal() as cleanup:
            cleanup.query(Compra).filter_by(EmailPersona=email).delete()
            cleanup.query(Copia).filter_by(EmailPersona=email).delete()
            cleanup.query(Juego).filter(Juego.IdJuego.in_(ids)).delete(synchronize_session=False)
            cleanup.query(Persona).filter_by(EmailPersona=email).delete()
            cleanup.commit()


if __name__ == "__main__":
    main()
