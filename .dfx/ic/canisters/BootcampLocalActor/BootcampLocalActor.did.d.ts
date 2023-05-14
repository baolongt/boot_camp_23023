import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface BootcampLocalActor {
  'getAllStudentsPrincipal' : ActorMethod<[], Array<Principal>>,
}
export interface _SERVICE extends BootcampLocalActor {}
