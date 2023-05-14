export const idlFactory = ({ IDL }) => {
  const BootcampLocalActor = IDL.Service({
    'getAllStudentsPrincipal' : IDL.Func(
        [],
        [IDL.Vec(IDL.Principal)],
        ['query'],
      ),
  });
  return BootcampLocalActor;
};
export const init = ({ IDL }) => { return []; };
