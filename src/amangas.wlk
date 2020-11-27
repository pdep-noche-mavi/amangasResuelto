class Participante {
	const property velocidad
	const property agilidad
	const property estrategia
	var rol = tripulante
	var property tiempoRestante = 100
	var vive = true
	var votos = 0
	const color 
	
	method rol() = rol
	
	method convertirEnImpostor(){
		rol = impostor	
	}
	
	method realizarTarea(tarea){
		rol.realizarTarea(self, tarea)
	}
	
	method sabotearTarea(tarea){
		rol.sabotearTarea(self, tarea)
	}
	method restarTiempo(tiempo){
		if (tiempoRestante - tiempo < 0){
			throw new DomainException(message="Se quedó sin tiempo")
		}
		tiempoRestante -= tiempo
	}
	
	method recuperarTiempo(tiempo){
		tiempoRestante += tiempo
	}
	
	method votar(participantes) = self.elegirAQuienVotar(participantes).agregarVoto()
	
	method elegirAQuienVotar(participantes) = participantes.anyOne()
	
	method esBlanco() = color.equals("Blanco")
	
	method votos() = votos
	
	method agregarVoto() {
		votos += 1
	}
	
	method vive() = vive
	
	method morir() {
		vive = false
	}
	
	method asesinar(participante) { 
		rol.asesinar(self, participante)
	}
	
	method reiniciarVotos(){
		votos = 0
	}
}

// TIPOS DE PARTICIPANTES

class Bromista inherits Participante {
	const amigue 
	override method elegirAQuienVotar(participantes) = if (participantes.contains(amigue)) amigue else super(participantes)
}

class Aliado inherits Participante {
	const amigue 
	override method elegirAQuienVotar(participantes) = super(participantes.filter({participante => not participante.equals(amigue)}))
}

class Conspiranoide inherits Participante {
	override method elegirAQuienVotar(participantes) {
		if (participantes.any({participante=>participante.esBlanco() })){
			return participantes.find({participante=>participante.esBlanco() }) 	
		} else {
			return super(participantes)
		}
	}
}

object tripulante {
	method realizarTarea(participante, tarea){
		const tiempo = tarea.tiempoDemora(participante)
		participante.restarTiempo(tiempo)
		tarea.realizada(true)
	}
	
	method sabotearTarea(participante, tarea){
		participante.recuperarTiempo(20)
	}
	
	method asesinar(participanteAsesino, participanteAAsesinar){
		throw new DomainException(message = "No soy asesino!")
	}
}

object impostor {
	method realizarTarea(participante, tarea){}
	
	method sabotearTarea(participante, tarea){
		participante.restarTiempo(10)
		tarea.realizada(false)
	}
	
	method asesinar(participanteAsesino, participanteAAsesinar){
		participanteAsesino.restarTiempo(5)
		participanteAAsesinar.morir()
	}
	
}

class Partida {
	const property maximoParticipantes = 15
	const property codigo
	const property participantes = []
	const tareas = []
	
	method sumar(participante, unCodigo){
		if (not (self.sePuedeSumar(unCodigo))){
			throw new DomainException(message="No se puede sumar a la partida")
		}
		participantes.add(participante)
	}
	
	method sePuedeSumar(unCodigo) = unCodigo.equals(codigo) and self.hayLugar()
	
	method hayLugar() = participantes.size() < maximoParticipantes
	
	method comenzarPartida(){
		participantes.take(self.cantidadImpostoresAGenerar()).forEach({
			participante => participante.convertirEnImpostor()
		})
	}
	
	method cantidadImpostoresAGenerar() = (participantes.size() / 10).truncate(0) + 1
	
	method participantesConVida() = participantes.filter({participante => participante.vive()})
	
	method realizarReunionDeEmergencia(){
		self.hacerVotaciones()
		self.expulsar()
		self.reiniciarVotos()
	}
	
	method reiniciarVotos(){
		self.participantesConVida().forEach({
			participante => participante.reiniciarVotos()
		})
	}
	method hacerVotaciones(){
		const participantesConVida = self.participantesConVida()
		participantesConVida.forEach({
			participante => participante.votar(participantesConVida.filter({ participanteVivo => not participanteVivo.equals(participante)}))
		})
	}
	
	method expulsar(){
		const expulsade = self.participantesConVida().max({participante => participante.votos()})
		participantes.remove(expulsade)
	}
	
	method victoriaTripulantes() = tareas.count({tarea => tarea.realizada()}) / tareas.size()
	
	method victoriaImpostores() = self.cantidadTripulantesAsesinados()   / self.cantidadTripulantes()

	method cantidadTripulantesAsesinados() = participantes.count({participante => (not participante.vive()) and participante.rol().equals(tripulante)})
	method cantidadTripulantes() = participantes.count({participante => participante.rol().equals(tripulante)})
	
	method gananTripulantes() = self.victoriaTripulantes() > self.victoriaImpostores()
	
	method partidaTerminada() = self.victoriaTripulantes() == 1 or self.victoriaImpostores() == 1 
	
	method agregarTarea(tarea){
		tareas.add(tarea)
	}
}
 
class TareaAgil {
	var property realizada = false
	
	method tiempoDemora(participante) = 10 / participante.velocidad()
}

class TareaMental {
	var property realizada = false
	const dificultad
	
	method tiempoDemora(participante) = dificultad / (participante.estrategia() + participante.agilidad())
}