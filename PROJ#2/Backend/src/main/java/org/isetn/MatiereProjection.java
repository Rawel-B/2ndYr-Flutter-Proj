package org.isetn;

import org.isetn.entities.Matiere;
import org.isetn.entities.Formation;
import org.springframework.data.rest.core.config.Projection;

@Projection(name = "p1", types = { Matiere.class })
public interface MatiereProjection {
	public String getNom();
	public Formation getFormation();
}
